#pragma once

#include "gui/gui2_element.h"

class GuiGraph : public GuiElement
{
private:
    std::vector<float> data;
    bool auto_scale_y;
    bool show_axis_zero;

public:
    GuiGraph(GuiContainer *owner, string id);

    GuiGraph *showAxisZero(bool value){show_axis_zero = value; return this;};
    void updateData(std::vector<float> data);

    virtual void onDraw(sp::RenderTarget &renderer) override;
};
