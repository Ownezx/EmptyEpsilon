#include "sensorScreen.h"
#include "i18n.h"
#include "math.h"

#include "components/radar.h"

#include "screenComponents/radarView.h"
#include "screenComponents/graph.h"

#include "gui/gui2_rotationdial.h"
#include "gui/gui2_button.h"
#include "gui/gui2_togglebutton.h"


SensorScreen::SensorScreen(GuiContainer *owner, CrewPosition crew_position)
    : GuiOverlay(owner, "SCIENCE_SCREEN", colorConfig.background), locked_to_position(false), current_bearing(0.0f)
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

    // radar or time sensor bottom 
    auto radar_container = new GuiElement(left_container, "");
    radar_container->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    auto time_sensor_container = new GuiElement(left_container, "");
    time_sensor_container->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)->setVisible(false)->setAttribute("layout", "vertical");

    // Fill right bar
    sensor_bearing = new GuiRotationDial(right_container, "BEARING_AIM", -90, 360 - 90, 0, [](float value){});
    sensor_bearing->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    

    auto lock_button = new GuiToggleButton(right_container, "SENSOR_LOCK_POSITION", tr("SensorButton", "Lock Position"), [this](bool value) {
        this->locked_to_position = value;
    });
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
    auto toggle_map_button = new GuiToggleButton(top_left_container, "SENSOR_TOGGLE_MAP", tr("SensorButton", "Toggle Map"), [radar_container, time_sensor_container](bool value)
    {
        radar_container->setVisible(value);
        time_sensor_container->setVisible(!value);
    });
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
    radar->setAutoCentering(false);
    radar->setPosition(0, 0, sp::Alignment::TopLeft)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    radar->setCallbacks(
        [this](sp::io::Pointer::Button button, glm::vec2 position) { //down
        },
        [this](glm::vec2 position) { //drag
        },
        [this](glm::vec2 position) { //up
        }
    );

    // Setup the sensor container
    biological_graph = new GuiGraph(sensor_container, "BIOLOGICAL_GRAPH");
    biological_graph->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    
}

void SensorScreen::onDraw(sp::RenderTarget& renderer)
{

}

void SensorScreen::onUpdate()
{
   
}

void SensorScreen::setSensorBearing(float bearing)
{

}