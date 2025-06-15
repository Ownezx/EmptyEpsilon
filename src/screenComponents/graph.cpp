#include <i18n.h>
#include "playerInfo.h"
#include "components/maneuveringthrusters.h"
#include "graph.h"
#include "powerDamageIndicator.h"
#include "snapSlider.h"
#include <vector>

#include "gui/gui2_progressbar.h"

GuiGraph::GuiGraph(GuiContainer *owner, string id)
    : GuiElement(owner, id), auto_scale_y(true), show_axis_zero(true)
{
    data.resize(512);
}

void GuiGraph::updateData(std::vector<float> new_data)
{
    if (new_data.size() != data.size())
    {
        data.resize(new_data.size());
    }

    for (int i = 0; i < data.size(); i++)
    {
        data[i] = new_data[i];
    }
}

void GuiGraph::onDraw(sp::RenderTarget &renderer)
{
    for (int i = 0; i < data.size(); i++)
    {
        data[i] = sinf(0.05 * (float)i);
    }

    // Find max
    float max = -std::numeric_limits<float>::infinity();
    float min = std::numeric_limits<float>::infinity();
    for (int i = 0; i < data.size(); i++)
    {
        if (data[i] > max)
            max = data[i];
        if (data[i] < min)
            min = data[i];
    }
    float range = max - min;

    if (show_axis_zero)
    {
        std::vector<glm::vec2> zero_line(2);
        zero_line[0] = glm::vec2(
            rect.position.x,
            rect.position.y + rect.size.y + rect.size.y * min / range);
        zero_line[1] = glm::vec2(
            rect.position.x + rect.size.x,
            rect.position.y + rect.size.y + rect.size.y * min / range);
        renderer.drawLineBlendAdd(zero_line, glm::u8vec4(100, 100, 100, 255));
    }

    std::vector<glm::vec2> graph_points(data.size());
    for (int i = 0; i < data.size(); i++)
    {
        graph_points[i] = glm::vec2(
            rect.position.x + rect.size.x * i / (float)data.size(),
            rect.position.y + rect.size.y - rect.size.y * ((data[i] - min) / range));
    }
    renderer.drawLineBlendAdd(graph_points, glm::u8vec4(255, 45, 84, 255)); // red
}
