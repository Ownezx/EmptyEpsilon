#include "rawScannerUtil.h"
#include "ecs/query.h"
#include "components/radar.h"
#include "playerInfo.h"
#include "random.h"
#include "components/collision.h"

#define NOISE_FLOOR 1

float sumFunction(float angle, float target_angle, float target_angle_width)
{
    float temp = (target_angle - angle) / target_angle_width;
    return 1 - temp * temp ;
}

// TODO: MAKE THIS USE A START ANGLE/END ANGLE AND RESOLUTION TO BE ABLE
// TO HANDLE THE CASE WHERE THE ANGLE OF THE OBJECT IS SMALLER THAN THE RESOLUTION
std::vector<RawScannerDataPoint> CalculateRawScannerData(glm::vec2 position, std::vector<float> angles, float range)
{

    // Initialize the data's amplitude along each of the three color bands.
    std::vector<RawScannerDataPoint> return_data_points(angles.size());

    // For each SpaceObject ...
    for (auto [entity, signature, dynamic_signature, transform] : sp::ecs::Query<RawRadarSignatureInfo, sp::ecs::optional<DynamicRadarSignatureInfo>, sp::Transform>())
    {
        // Don't measure our own ship.
        if (entity == my_spaceship)
        {
            printf("Skipping own ship\n");
            continue;
        }

        // Initialize angle, distance, and scale variables.
        float dist = glm::length(transform.getPosition() - position);

        // If the object is further than the maximum range
        // ignore it
        if (dist > range)
        {
            printf("Skipping object at distance %f, further than range %f\n", dist, range);
            continue;
        }

        float scale = 1.0;
        // The further away the object is, the less its effect on radar data.
        if (dist > range)
            scale = 1.0f - ((dist - range) / range);

        auto physics = entity.getComponent<sp::Physics>();

        // Get object position
        float a_center = vec2ToAngle(transform.getPosition() - position);

        // p is used for quadratic interpolation later
        float p = 0;
        float a_diff;

        // If we're adjacent to the object ...
        if (physics && dist <= physics->getSize().x)
        {
            p = dist / physics->getSize().x;
            p *= p;
            a_diff = M_PI;
        }
        else
        {
            // Otherwise, measure the affected range of angles by the object's
            // distance and radius.
            a_diff = glm::degrees(asinf((physics ? physics->getSize().x : 300.0f) / dist));
        }

        // Now add the value to all relevant point
        for (int i = 0; i < (int)angles.size(); i++)
        {
            if (abs(angles[i] - a_center) > abs(a_diff))
                continue;

            float summing_function_value = 0;
            if (p == 0)
            {
                // If we do not intersect with the object we just use the sensor
                // signal function 1 - (x/(2*a_diff)^2
                summing_function_value = sumFunction(angles[i], a_center, a_diff);
            }
            else
            {
                // If we intersect with it we do a quadratic interpolation with 1 depending on the closeness.
                summing_function_value = sumFunction(angles[i], a_center, M_PI) * p + 1 + p;
            }

            // Now we do the first sum for things
            float g = signature.biological;
            float r = signature.electrical;
            float b = signature.gravity;

            // Same with dynamic source
            if (dynamic_signature)
            {
                g += dynamic_signature->biological;
                r += dynamic_signature->electrical;
                b += dynamic_signature->gravity;
            }

            return_data_points[i].biological += g * summing_function_value * scale;
            return_data_points[i].electrical += r * summing_function_value * scale;
            return_data_points[i].gravity += b * summing_function_value * scale;
        }
    }

    RawRadarSignatureInfo signatures[angles.size()];

    // For each data point ...
    // Now post processing to be as close to what it was before
    for (int i = 0; i < (int)angles.size(); i++)
    {
        //return_data_points[i].biological = std::clamp(return_data_points[i].biological, 0.0f, 1.0f);
        //return_data_points[i].electrical = std::clamp(return_data_points[i].electrical, 0.0f, 1.0f);
        //return_data_points[i].gravity = std::clamp(return_data_points[i].gravity, 0.0f, 1.0f);

        return_data_points[i].biological = random(-NOISE_FLOOR, NOISE_FLOOR) + return_data_points[i].biological * 30;
        return_data_points[i].electrical = random(-NOISE_FLOOR, NOISE_FLOOR) + random(-20, 20) * return_data_points[i].electrical;
        return_data_points[i].gravity = random(-NOISE_FLOOR, NOISE_FLOOR) * (1.0f - return_data_points[i].gravity) + 40 * return_data_points[i].gravity;
    }

    return return_data_points;
}
