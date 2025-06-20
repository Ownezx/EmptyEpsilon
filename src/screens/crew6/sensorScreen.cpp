#include "sensorScreen.h"
#include "i18n.h"
#include "math.h"

#include "components/radar.h"

#include "screenComponents/radarView.h"
#include "screenComponents/graph.h"
#include "screenComponents/graphLabel.h"
#include "screenComponents/SensorScreenOverlay.h"

#include "gui/gui2_button.h"
#include "gui/gui2_togglebutton.h"

#include "utils/rawScannerUtil.h"

SensorScreen::SensorScreen(GuiContainer *owner, CrewPosition crew_position)
    : GuiOverlay(owner, "SCIENCE_SCREEN",
                 colorConfig.background),
      locked_to_position(false),
      min_arc_size(10.0f),
      point_count(512),
      target_map_zoom(50000.f)
{
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
    graph_label = new GuiGraphLabel(left_container, "");
    graph_label->setSize(GuiElement::GuiSizeMax, 60);
    graph_label->setMajorTickSize(20)->setMinorTickNumber(1)->setDisplayLabelText(true);
    graph_label->setModulo(360.0f);

    // radar or time sensor bottom
    // Try to encapsulate this in a gui element to do an overlay!
    auto radar_container = new GuiElement(left_container, "");
    radar_container->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    auto fill_element = new GuiElement(right_container, "");
    fill_element->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    auto lock_button = new GuiToggleButton(right_container, "SENSOR_LOCK_POSITION", tr("SensorButton", "Lock Position"), [this](bool value)
                                           { this->locked_to_position = value; });
    lock_button->setSize(GuiElement::GuiSizeMax, 50);

    auto mark_bearing_button = new GuiButton(right_container, "SENSOR_MARK_BEARING", tr("SensorButton", "Mark Bearing"), [this]()
                                             { this->scan_overlay->addMarker(); });
    mark_bearing_button->setSize(GuiElement::GuiSizeMax, 50);

    auto remove_last_mark_button = new GuiButton(right_container, "SENSOR_REMOVE_LAST_MARK", tr("SensorButton", "Remove Last Mark"), [this]()
                                                 { this->scan_overlay->removePreviousMarker(); });
    remove_last_mark_button->setSize(GuiElement::GuiSizeMax, 50);

    auto remove_oldest_mark_button = new GuiButton(right_container, "SENSOR_REMOVE_OLDEST_MARK", tr("SensorButton", "Remove Oldest Mark"), [this]()
                                                   { this->scan_overlay->removeOldestMarker(); });
    remove_oldest_mark_button->setSize(GuiElement::GuiSizeMax, 50);

    auto reset_marks_button = new GuiButton(right_container, "SENSOR_RESET_MARKS", tr("SensorButton", "Reset Marks"), [this]()
                                            { this->scan_overlay->clearMarkers(); });
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

    auto biological_button = new GuiToggleButton(top_left_container, "SENSOR_BIOLOGICAL", tr("SensorButton", "Biological"), [this](bool value)
                                                 {
        if (value)
            this->radar->enableBiological();
        else
            this->radar->disableBiological(); });
    biological_button->setSize(GuiElement::GuiSizeMax, 50);

    auto electrical_button = new GuiToggleButton(top_left_container, "SENSOR_ELECTRICAL", tr("SensorButton", "Electrical"), [this](bool value)
                                                 {
        if (value)
            this->radar->enableElectrical();
        else
            this->radar->disableElectrical(); });
    electrical_button->setSize(GuiElement::GuiSizeMax, 50);

    auto gravity_button = new GuiToggleButton(top_left_container, "SENSOR_GRAVITY", tr("SensorButton", "Gravity"), [this](bool value)
                                              {
        if (value)
            this->radar->enableGravity();
        else
            this->radar->disableGravity(); });
    gravity_button->setSize(GuiElement::GuiSizeMax, 50);

    // Setup the radar container
    targets.setAllowWaypointSelection();
    radar = new GuiRadarView(radar_container, "SENSOR_RADAR", 50000.0f, &targets);
    radar->longRange()->enableWaypoints()->enableCallsigns()->setStyle(GuiRadarView::Rectangular)->setFogOfWarStyle(GuiRadarView::FriendlysShortRangeFogOfWar);
    radar->setAutoCentering(true);
    radar->enableSignatures();
    radar->setPosition(0, 0, sp::Alignment::TopLeft)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    radar->setCallbacks(
        [this](sp::io::Pointer::Button button, glm::vec2 position) { // down
            if (button == sp::io::Pointer::Button::Left)
            {
                setSensorTarget(position);
            }
        },
        [this](glm::vec2 position)
        {
            setSensorTarget(position);
        },
        [this](glm::vec2 position) { // up
        });

    scan_overlay = new SensorScreenOverlay(radar, "");

    // Setup the sensor container
    electrical_graph = new GuiGraph(sensor_container, "BIOLOGICAL_GRAPH", colorConfig.overlay_electrical_signal);
    electrical_graph->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    electrical_graph->showAxisZero(false);

    biological_graph = new GuiGraph(sensor_container, "BIOLOGICAL_GRAPH", colorConfig.overlay_biological_signal);
    biological_graph->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    biological_graph->showAxisZero(false);

    gravity_graph = new GuiGraph(sensor_container, "BIOLOGICAL_GRAPH", colorConfig.overlay_gravity_signal);
    gravity_graph->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    gravity_graph->showAxisZero(false);
}

void SensorScreen::onDraw(sp::RenderTarget &renderer)
{
    float mouse_wheel_delta = keys.zoom_in.getValue() - keys.zoom_out.getValue();
    if (mouse_wheel_delta != 0)
    {
        float temp = scan_overlay->getArc() + mouse_wheel_delta * 10.0f;
        temp = glm::clamp(temp, min_arc_size, 360.0f);
        if (temp > 150)
        {
            graph_label->setMajorTickSize(20);
            graph_label->setMinorTickNumber(1);
        }
        else if (temp > 70)
        {
            graph_label->setMajorTickSize(10);
            graph_label->setMinorTickNumber(1);
        }
        else if (temp > 10)
        {
            graph_label->setMajorTickSize(5);
            graph_label->setMinorTickNumber(4);
        }
        else
        {
            graph_label->setMajorTickSize(1);
            graph_label->setMinorTickNumber(0);
        }
        scan_overlay->setArc(temp);
    }

    std::vector<RawScannerDataPoint> scanner_data =
        CalculateRawScannerData(this->radar->getViewPosition(),
                                scan_overlay->getBearing() - scan_overlay->getArc() / 2.0f - 90.0f,
                                scan_overlay->getArc(),
                                point_count,
                                radar->getDistance() * 2, // TODO: use the raw data
                                radar->getNoiseFloor());

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

    graph_label->setStart(scan_overlay->getBearing() - scan_overlay->getArc() / 2.0f);
    graph_label->setStop(scan_overlay->getBearing() + scan_overlay->getArc() / 2.0f);
    electrical_graph->updateData(electrical_points);
    biological_graph->updateData(biological_points);
    gravity_graph->updateData(gravity_points);

    // TODO: use a time since last frame variable
    // this is frame dependent...
    updateMapZoom(0.1);
}

void SensorScreen::setSensorTarget(glm::vec2 position)
{
    scan_overlay->setCurrentTarget(position);
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