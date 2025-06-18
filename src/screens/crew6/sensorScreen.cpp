#include "sensorScreen.h"
#include "i18n.h"
#include "math.h"

#include "components/radar.h"

#include "systems/beamweapon.h"

#include "screenComponents/radarView.h"
#include "screenComponents/graph.h"

#include "gui/gui2_button.h"
#include "gui/gui2_togglebutton.h"

#include "utils/rawScannerUtil.h"

SensorScreen::SensorScreen(GuiContainer *owner, CrewPosition crew_position)
    : GuiOverlay(owner, "SCIENCE_SCREEN",
      colorConfig.background),
      locked_to_position(false),
      current_bearing(0.0f),
      min_arc_size(10.0f),
      point_count(512),
      target_map_zoom(50000.f)
{
    current_arc_size = 360.0f - 360.0f / (point_count - 1);

    auto container = new GuiElement(this, "");
    container->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)->setAttribute("layout", "horizontal");

    auto left_container = new GuiElement(container, "");
    left_container->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)->setAttribute("layout", "vertical");
    left_container->setMargins(20);

    auto right_container = new GuiElement(container, "");
    right_container->setSize(220, GuiElement::GuiSizeMax)->setAttribute("layout", "vertical");
    right_container->setMargins(20);

    auto top_left_container = new GuiElement(left_container, "");
    top_left_container->setSize(GuiElement::GuiSizeMax, 50)->setAttribute("layout", "horizontal");
    top_left_container->setMargins(20);

    // Sensor graph
    auto sensor_container = new GuiElement(left_container, "");
    sensor_container->setSize(GuiElement::GuiSizeMax, 150);

    // radar or time sensor bottom
    auto radar_container = new GuiElement(left_container, "");
    radar_container->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    auto time_sensor_container = new GuiElement(left_container, "");
    time_sensor_container->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)->setVisible(false)->setAttribute("layout", "vertical");

    auto lock_button = new GuiToggleButton(right_container, "SENSOR_LOCK_POSITION", tr("SensorButton", "Lock Position"), [this](bool value)
                                           { this->locked_to_position = value; });
    lock_button->setSize(GuiElement::GuiSizeMax, 50);

    auto mark_bearing_button = new GuiButton(right_container, "SENSOR_MARK_BEARING", tr("SensorButton", "Mark Bearing"), []() {});
    mark_bearing_button->setSize(GuiElement::GuiSizeMax, 50);

    auto remove_oldest_mark_button = new GuiButton(right_container, "SENSOR_REMOVE_OLDEST_MARK", tr("SensorButton", "Remove Oldest Mark"), []() {});
    remove_oldest_mark_button->setSize(GuiElement::GuiSizeMax, 50);

    auto reset_marks_button = new GuiButton(right_container, "SENSOR_RESET_MARKS", tr("SensorButton", "Reset Marks"), []() {});
    reset_marks_button->setSize(GuiElement::GuiSizeMax, 50);

    auto link_probe_button = new GuiToggleButton(right_container, "SENSOR_LINK_PROBE", tr("SensorButton", "Link Probe"), [](bool value) {});
    link_probe_button->setSize(GuiElement::GuiSizeMax, 50);

    // Top buttons
    auto toggle_map_button = new GuiToggleButton(top_left_container, "SENSOR_TOGGLE_MAP_ZOOM", tr("SensorButton", "Toggle Map Zoom"), [this](bool value)
                                                 {
        if (value)
            this->target_map_zoom = 50000.0f;
        else
            this->target_map_zoom = 10000.0f; });
    toggle_map_button->setValue(true)->setSize(GuiElement::GuiSizeMax, 50);

    auto biological_button = new GuiToggleButton(top_left_container, "SENSOR_BIOLOGICAL", tr("SensorButton", "Biological"), [](bool value) {});
    biological_button->setSize(GuiElement::GuiSizeMax, 50);

    auto electrical_button = new GuiToggleButton(top_left_container, "SENSOR_ELECTRICAL", tr("SensorButton", "Electrical"), [](bool value) {});
    electrical_button->setSize(GuiElement::GuiSizeMax, 50);

    auto gravity_button = new GuiToggleButton(top_left_container, "SENSOR_GRAVITY", tr("SensorButton", "Gravity"), [](bool value) {});
    gravity_button->setSize(GuiElement::GuiSizeMax, 50);

    // Setup the radar container
    targets.setAllowWaypointSelection();
    radar = new GuiRadarView(radar_container, "SENSOR_RADAR", 50000.0f, &targets);
    radar->longRange()->enableWaypoints()->enableCallsigns()->setStyle(GuiRadarView::Rectangular)->setFogOfWarStyle(GuiRadarView::FriendlysShortRangeFogOfWar);
    radar->setAutoCentering(true);
    radar->setPosition(0, 0, sp::Alignment::TopLeft)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    radar->setCallbacks(
        [this](sp::io::Pointer::Button button, glm::vec2 position) { // down
            if (button == sp::io::Pointer::Button::Left)
            {
                setSensorBearing(vec2ToAngle(position - this->radar->getViewPosition()) + 90);
            }
        },
        [this](glm::vec2 position)
        {
            setSensorBearing(vec2ToAngle(position - this->radar->getViewPosition()) + 90);
        },
        [this](glm::vec2 position) { // up
        });

    // Setup the sensor container
    electrical_graph = new GuiGraph(sensor_container, "BIOLOGICAL_GRAPH", glm::u8vec4(255, 45, 84, 255));
    electrical_graph->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    electrical_graph->showAxisZero(false)->setYlimit(-5.0f, 15.0f);

    biological_graph = new GuiGraph(sensor_container, "BIOLOGICAL_GRAPH", glm::u8vec4(65, 255, 81, 255));
    biological_graph->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    biological_graph->showAxisZero(false)->setYlimit(-5.0f, 15.0f);

    gravity_graph = new GuiGraph(sensor_container, "BIOLOGICAL_GRAPH", glm::u8vec4(70, 120, 255, 255));
    gravity_graph->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    gravity_graph->showAxisZero(false)->setYlimit(-5.0f, 15.0f);
}

void SensorScreen::onDraw(sp::RenderTarget &renderer)
{
    float mouse_wheel_delta = keys.zoom_in.getValue() - keys.zoom_out.getValue();
    if (mouse_wheel_delta != 0)
    {
        this->current_arc_size += mouse_wheel_delta * 10.0f;
        this->current_arc_size = glm::clamp(this->current_arc_size, this->min_arc_size, 360.0f - 360.0f / (this->point_count + 1));
        printf("Current arc size: %.2f\n", this->current_arc_size);
    }

    std::vector<RawScannerDataPoint> scanner_data =
        CalculateRawScannerData(this->radar->getViewPosition(),
                                current_bearing - current_arc_size / 2.0f - 90.0f,
                                current_arc_size,
                                point_count,
                                radar->getDistance() * 2);

    // separate in three vectors
    std::vector<float> electrical_points = std::vector<float>(point_count);
    std::vector<float> biological_points = std::vector<float>(point_count);
    std::vector<float> gravity_points = std::vector<float>(point_count);

    for (size_t i = 0; i < point_count; i++)
    {
        electrical_points[i] = scanner_data[i].electrical;
        biological_points[i] = scanner_data[i].biological;
        gravity_points[i] = scanner_data[i].gravity;
    }

    electrical_graph->updateData(electrical_points);
    biological_graph->updateData(biological_points);
    gravity_graph->updateData(gravity_points);

    drawArc(renderer,
            radar->getCenterPoint(),
            current_bearing - current_arc_size / 2.0f - 90.0f,
            current_arc_size,
            fmin(radar->getRect().size.x, radar->getRect().size.y) / 2 + 20,
            glm::u8vec4(255, 255, 255, 100));

    // TODO: use a time since last frame variable
    // this is frame dependent...
    updateMapZoom(0.1);
}

void SensorScreen::setSensorBearing(float bearing)
{
    this->current_bearing = bearing;
    if (this->current_bearing < 0)
        this->current_bearing += 360.0f;
}

void SensorScreen::updateMapZoom(float delta)
{
    float temp = this->radar->getDistance() - (this->radar->getDistance() - this->target_map_zoom) * delta;
    if (temp < 10)
        this->radar->setDistance(target_map_zoom);
    else
        this->radar->setDistance(temp);
}

void SensorScreen::onUpdate()
{
}