#include "rawScannerUtil.h"
#include "ecs/query.h"
#include "components/radar.h"
#include "components/radarblock.h"
#include "playerInfo.h"
#include "random.h"
#include "components/collision.h"

float sumFunction(float angle, float target_angle, float target_angle_width)
{
    // Calculate the minimum unsigned angle difference
    float angle_diff = fmod(fabs(angle - target_angle), 360.0f);
    if (angle_diff > 180.0f)
        angle_diff = 360.0f - angle_diff;

    float temp = angle_diff / target_angle_width;
    return 1 - temp * temp;
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

std::vector<RawScannerDataPoint> CalculateRawScannerData(glm::vec2 position, float start_angle, float arc_size, uint point_count, float range, float noise_floor)
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
        angles[i] = fmod(start_angle + i * resolution, 360.0f);
        if (angles[i] < 0.0f)
            angles[i] += 360.0f;
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


        // This is used to activate the quadratic interpolation
        bool is_close = false;
        float scale = 1.0;

        float size = GetEntityRadarTraceSize(entity);
        printf("Size %f, dist %f\n", size, dist);
        if (size > dist)
        {
            scale = 1.0f;
            is_close = true;
        }
        else
        {
            // if we are out of the object, we want to
            // have a linear interpolation to the range
            scale = 1 - (dist - size) / (range - size);
        }

        // Get object position
        float a_center = vec2ToAngle(transform.getPosition() - position);

        float a_diff;

        // Special case to use a different summing function if the object is very far
        float is_far = false;
        // p is used for interpolation
        float p = 0;

        // Calculate the angle of the object
        if (is_close)
        {
            p = 1 - dist / size;
            // p *= p;
            // interpolation
            a_diff = M_PI + M_PI * p * p;
        }
        else
        {
            // Exposed angular size of the object
            a_diff = glm::degrees(asinf(size / dist));
            // If we are very fare we need to use a different summing function
            // To make sure we see it on the radar
            if (a_diff < resolution /2 )
            {
                is_far = true;
                a_diff += 2 * resolution;
            }
        }

        // Changing origin to the start angle to make it easier to understand
        float transformed_target_center = fmod(a_center - start_angle, 360.0f);
        if (transformed_target_center < 0)
            transformed_target_center += 360.0f;
        float transformed_target_start_angle = fmod(a_center - a_diff - start_angle, 360.0f);
        if (transformed_target_start_angle < 0)
            transformed_target_start_angle += 360.0f;
        float transformed_target_stop_angle = fmod(a_center + a_diff - start_angle, 360.0f);
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
                summing_function_value = sumFunction(angles[i % point_count], a_center, a_diff) * (1 - p)  + p;
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

        return_data_points[i].biological = random(-noise_floor, noise_floor) + return_data_points[i].biological * 40;
        return_data_points[i].electrical = random(-noise_floor, noise_floor) + random(-20, 40) * return_data_points[i].electrical;
        return_data_points[i].gravity = random(-noise_floor, noise_floor) * (1.0f - return_data_points[i].gravity) + 60 * return_data_points[i].gravity;

        if (return_data_points[i].biological > 0)
            return_data_points[i].biological = sqrt(1 + return_data_points[i].biological) - 1;
        else
            return_data_points[i].biological = -(sqrt(1 - return_data_points[i].biological) - 1);

        if (return_data_points[i].electrical > 0)
            return_data_points[i].electrical = sqrt(1 + return_data_points[i].electrical) - 1;
        else
            return_data_points[i].electrical = -(sqrt(1 - return_data_points[i].electrical) - 1);

        if (return_data_points[i].gravity > 0)
            return_data_points[i].gravity = sqrt(1 + return_data_points[i].gravity) - 1;
        else
            return_data_points[i].gravity = -(sqrt(1 - return_data_points[i].gravity) - 1);
    }

    return return_data_points;
}

std::vector<RawScannerDataPoint> Calculate360RawScannerData(glm::vec2 position, uint point_count, float range, float noise_floor)
{
    return CalculateRawScannerData(position, 0, 360 - 360 / float(point_count), point_count, range, noise_floor);
}

float GetEntityRadarTraceSize(sp::ecs::Entity entity)
{
    float size;
    auto signature = entity.getComponent<RawRadarSignatureInfo>();
    if (signature && signature->size != 0)
        return signature->size;

    // Fallback to physics entity
    auto physics = entity.getComponent<sp::Physics>();
    if(physics)
        return physics->getSize().x;

    // Fallback to radar block for nebulas
    auto radar_block = entity.getComponent<RadarBlock>();
    if (radar_block)
        return radar_block->range;
    
    return 300.0f;
}
