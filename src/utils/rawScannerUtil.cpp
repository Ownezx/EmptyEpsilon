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

// TODO: MAKE THIS USE A START ANGLE/END ANGLE AND RESOLUTION TO BE ABLE
// TO HANDLE THE CASE WHERE THE ANGLE OF THE OBJECT IS SMALLER THAN THE RESOLUTION
std::vector<RawScannerDataPoint> CalculateRawScannerData(glm::vec2 position, float start_angle, float arc_size, uint point_count, float range)
{

    // Initialize the data's amplitude along each of the three color bands.
    std::vector<RawScannerDataPoint> return_data_points(point_count);

    float resolution = arc_size / (point_count-1);

    // Pre allocate the angles for computational speed
    float angles[point_count];
    for (int i = 0; i < point_count; i++)
    {
        // Here we do not want to wrap around as the sum function needs it to not wrap around.
        angles[i] = start_angle + i * resolution;
    }
    
    bool arc_loops_on_itself = false;
    if (arc_size == 360 - resolution)
        arc_loops_on_itself = true;


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

        // Here we need to find where the angle starts to do the sum
        int target_start_angle_index = (int) ceil(((a_center - a_diff) - start_angle) / resolution);
        int target_stop_angle_index = (int) ceil(((a_center + a_diff) - start_angle) / resolution);

        // Special case to use a different summing function if the object is very far
        bool is_far = false;
        if (target_stop_angle_index - target_start_angle_index <= 3)
            is_far = true;

        // Handle the cases where the the arc loops on itself.
        if (!arc_loops_on_itself)
        {
            // If the start angle is negative, we need to wrap it around
            if (target_start_angle_index < 0)
            {
                target_start_angle_index += point_count;
                target_stop_angle_index += point_count;
            }
            // Prevent overflow
            if (target_stop_angle_index >= point_count)
                target_stop_angle_index = point_count - 1;
        }

        printf("Indexes: %d to %d\n", target_start_angle_index, target_stop_angle_index);
        // Now add the value to all relevant point
        for (int i = target_start_angle_index; i < target_stop_angle_index; i++)
        {
            printf("Adding to point %d, corresponding to angle %f\n", i, angles[i % point_count]);
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
                // If we intersect with it we do a quadratic interpolation with 1 depending on the closeness.
                summing_function_value = sumFunction(angles[i % point_count], a_center, M_PI) * p + 1 + p;
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
