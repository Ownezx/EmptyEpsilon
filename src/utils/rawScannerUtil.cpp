#include "rawScannerUtil.h"
#include "ecs/query.h"
#include "components/radar.h"
#include "playerInfo.h"
#include "random.h"
#include "components/collision.h"
#include <cmath>

#define NOISE_FLOOR 1

float sumFunction(float angle, float target_angle, float target_angle_width)
{
    float temp = (target_angle - angle) / target_angle_width;
    return 1 - temp * temp ;
}

float farSumFunction(float angle, float target_angle, float target_angle_width, float resolution)
{
    // If the whole target width is within one resolution, we just return 1.
    if (target_angle_width < resolution / 2 && abs(angle - target_angle) < resolution / 2)
        return 1;
    // If none of the target angle is within the resolution, we return 0.
    if (abs(angle - target_angle) > resolution / 2 + target_angle_width / 2)
        return 0;
    // Otherwise, we return a linear interpolation between 0 and 1.
    float p = 2 * abs(target_angle - angle) / (resolution  + target_angle_width );
    return 1 - p;

}

std::vector<RawScannerDataPoint> CalculateRawScannerData(glm::vec2 position, float start_angle, float arc_size, uint point_count, float range)
{
    // Sanitize the input parameters.
    if (start_angle<0)
        start_angle += 360.0f;
    
    start_angle = fmod(start_angle, 360.0f);
    arc_size = glm::clamp(arc_size, 0.0f, 360.0f - 360.0f / point_count);

    
    // Initialize the data's amplitude along each of the three color bands.
    std::vector<RawScannerDataPoint> return_data_points(point_count);

    float resolution = arc_size / (point_count-1);

    // Pre allocate the angles for computational speed
    float angles[point_count];
    for (int i = 0; i < point_count; i++)
    {
        // Here we do not want to wrap around as the sum function needs it to not wrap around.
        angles[i] = fmodf(start_angle + i * resolution, 360.0f);
    }

    // For each SpaceObject ...
    for (auto [entity, signature, dynamic_signature, transform] : sp::ecs::Query<RawRadarSignatureInfo, sp::ecs::optional<DynamicRadarSignatureInfo>, sp::Transform>())
    {
        // Don't measure our own ship.
        if (entity == my_spaceship)
            continue;

        // Initialize angle, distance, and scale variables.
        float dist = glm::length(transform.getPosition() - position);

        // If the object is further than the maximum range
        // ignore it
        if (dist > range)
            continue;

        float scale = 1.0;
        // The further away the object is, the less its effect on radar data.
        if (dist > range/2)
            scale = 1.0f - 2 * ((dist - range / 2) / range);

        auto physics = entity.getComponent<sp::Physics>();

        // Get object position
        float a_center = fmod(vec2ToAngle(transform.getPosition() - position), 180.0f);

        float a_diff;

        // This is used to activate the quadratic interpolation
        bool is_close = false;
        // Special case to use a different summing function if the object is very far
        float is_far = false;
        float is_far_additional_size = 0.0f;
        // p is used for quadratic interpolation
        float p = 0;

        // If we're adjacent to the object ...
        if (physics && dist <= physics->getSize().x)
        {
            p = dist / physics->getSize().x;
            p *= p;
            a_diff = M_PI / 2.0f;
            is_close = true;
        }
        else
        {
            // Exposed angular size of the object
            a_diff = glm::degrees(asinf((physics ? physics->getSize().x : 300.0f) / dist));
            // If we are very fare we need to use a different summing function
            // To make sure we see it on the radar
            if (a_diff < resolution /2 )
            {
                is_far = true;
                is_far_additional_size = 2 * resolution;
            }
        }

        // Changing origin to the start angle to make it easier to understand
        float transformed_target_center = fmod(a_center - start_angle, 360.0f);
        if (transformed_target_center < 0)
            transformed_target_center += 360.0f;
        float transformed_target_start_angle = fmod(a_center - a_diff - is_far_additional_size - start_angle, 360.0f);
        if (transformed_target_start_angle < 0)
            transformed_target_start_angle += 360.0f;
        float transformed_target_stop_angle = fmod(a_center + a_diff + is_far_additional_size - start_angle, 360.0f);
        if (transformed_target_stop_angle < 0)
            transformed_target_stop_angle += 360.0f;
        float transformed_stop_angle = arc_size;


        // Find min an max angle from change of origin
        float max_angle = glm::min(
            transformed_target_stop_angle,
            transformed_stop_angle);
        
        float min_angle;
        if (transformed_target_start_angle > transformed_target_stop_angle)
        {
            min_angle = 0.0f; 
        }
        else
        {
            min_angle = transformed_target_start_angle;
        }
        

        // Here we need to find where the angle starts to do the sum
        int target_start_angle_index = (int)ceil(min_angle  / resolution);
        int target_stop_angle_index = (int)floor(max_angle  / resolution);

        for (int i = target_start_angle_index; i < target_stop_angle_index; i++)
        {
            float summing_function_value = 0;
            if (p == 0)
            {
                // If we do not intersect with the object we just use the sensor
                // signal function 1 - (x/(2*a_diff)^2
                if (is_far)
                    summing_function_value = farSumFunction(angles[i % point_count], a_center, a_diff, resolution);
                else
                     summing_function_value = sumFunction(angles[i % point_count], a_center, a_diff);
            }
            else
            {
                // If are in the object, we do a quadratic interpolation with 1 depending on the closeness.
                summing_function_value = sumFunction(angles[i % point_count], transformed_target_center, a_diff) * p + 1 - p;
            }

            float g = signature.biological;
            float r = signature.electrical;
            float b = signature.gravity;

            if (dynamic_signature)
            {
                g += dynamic_signature->biological;
                r += dynamic_signature->electrical;
                b += dynamic_signature->gravity;
            }

            return_data_points[i % point_count].biological += g * summing_function_value * scale;
            return_data_points[i % point_count].electrical += r * summing_function_value * scale;
            return_data_points[i % point_count].gravity += b * summing_function_value * scale;
        }
    }

    // For each data point ...
    // Now post processing to be as close to what it was before
    for (int i = 0; i < point_count; i++)
    {

        return_data_points[i].biological = random(0, NOISE_FLOOR) + return_data_points[i].biological * 40;
        return_data_points[i].electrical = random(0, NOISE_FLOOR) + random(0, 60) * return_data_points[i].electrical;
        return_data_points[i].gravity = random(0, NOISE_FLOOR) * (1.0f - return_data_points[i].gravity) + 60 * return_data_points[i].gravity;

        return_data_points[i].biological = 2 * (sqrtf(1 + return_data_points[i].biological) - 1);
        return_data_points[i].electrical = 2 * (sqrtf(1 + return_data_points[i].electrical) - 1);
        return_data_points[i].gravity = 2 * (sqrtf(1 + return_data_points[i].gravity) - 1);
    }

    return return_data_points;
}

std::vector<RawScannerDataPoint> Calculate360RawScannerData(glm::vec2 position, uint point_count, float range)
{
    return CalculateRawScannerData(position, 0, 360 - 360 / float(point_count), point_count, range);
}
