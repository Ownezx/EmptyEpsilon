#pragma once

#include "gui/gui2_element.h"

class GuiGraph : public GuiElement
{
private:
    std::vector<float> data;
    bool auto_scale_y;
    bool show_axis_zero;
    float y_min;
    float y_max;
    glm::u8vec4 color;

public:
    GuiGraph(GuiContainer *owner, string id, glm::u8vec4 color);

    GuiGraph *showAxisZero(bool value){show_axis_zero = value; return this;};
    void updateData(std::vector<float> data);
    void setYlimit(float min, float max);
    void setAutoScaleY(bool value) { auto_scale_y = value; }

    virtual void onDraw(sp::RenderTarget &renderer) override;
};
