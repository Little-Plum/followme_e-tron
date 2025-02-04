####    Follow Me   ####
####    Gijs de Rooy (Original)    ####
####    Sidi Liang    ####

#// This program is free software: you can redistribute it and/or modify
#// it under the terms of the GNU General Public License as published by
#// the Free Software Foundation, either version 2 of the License, or
#// (at your option) any later version.

#// This program is distributed in the hope that it will be useful,
#// but WITHOUT ANY WARRANTY; without even the implied warranty of
#// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#// GNU General Public License for more details.

#// You should have received a copy of the GNU General Public License
#// along with this program.  If not, see <https://www.gnu.org/licenses/>.

io.include("library.nas");

props.getNode("/sim/gui/dialogs/vehicle_config/dialog",1);
var configDialog = gui.Dialog.new("/sim/gui/dialogs/vehicle_config/dialog", "Aircraft/followme_e-tron/gui/dialogs/config-dialog.xml");

var tyreSmoke_0 = aircraft.tyresmoke.new(0, auto = 1, diff_norm = 0.4, check_vspeed = 0);
var tyreSmoke_1 = aircraft.tyresmoke.new(1, auto = 1, diff_norm = 0.4, check_vspeed = 0);
var tyreSmoke_2 = aircraft.tyresmoke.new(2, auto = 1, diff_norm = 0.4, check_vspeed = 0);
var tyreSmoke_3 = aircraft.tyresmoke.new(3, auto = 1, diff_norm = 0.4, check_vspeed = 0);


var frontleft_door = aircraft.door.new("/controls/doors/frontleft", 1);
frontleft_door.informationNode = vInfo.controls.doors.FL;
frontleft_door.doorNum = "1";
var frontright_door = aircraft.door.new("/controls/doors/frontright", 1);
frontright_door.informationNode = vInfo.controls.doors.FR;
frontright_door.doorNum = "2";
var rearleft_door = aircraft.door.new("/controls/doors/rearleft", 1);
rearleft_door.informationNode = vInfo.controls.doors.RL;
rearleft_door.doorNum = "3";
var rearright_door = aircraft.door.new("/controls/doors/rearright", 1);
rearright_door.informationNode = vInfo.controls.doors.RR;
rearright_door.doorNum = "4";

var charging_cap = aircraft.door.new("/controls/doors/charging_cap", 1);
charging_cap.doorNum = 0;
charging_cap.informationNode = vInfo.controls.doors.charging_cap;

aircraft.door.toggle = func(){
    var pos = me.getpos();
    me.informationNode.setValue(1 - me.getpos());
    if(pos == 0){
        me.open();
        if(me.doorNum) playAudio(file: 'door_open.wav', queue: 'fx_door_'~me.doorNum);
    }
    if(pos == 1){
        me.close();
        if(me.doorNum) playAudio(file: 'door_shut.wav', queue: 'fx_door_'~me.doorNum);
    }
}

beacon_switch = props.globals.getNode("controls/switches/warninglight", 2);
var beacon = aircraft.light.new( "/sim/model/lights/warning", [0.5, 0.5], "/controls/lighting/warning" );
beacon_switch = props.globals.getNode("controls/switches/indicator-left", 2);
var beacon = aircraft.light.new( "/sim/model/lights/indicator-left", [0.5, 0.5], "/controls/lighting/indicator-left");
beacon_switch = props.globals.getNode("controls/switches/indicator-right", 2);
var beacon = aircraft.light.new( "/sim/model/lights/indicator-right", [0.5, 0.5], "/controls/lighting/indicator-right");

#//Wiper
var wiperMode = 0;
var wiperSwitchNode = props.globals.getNode("/controls/wiper/frontwiper_switch", 1);
var wiper = aircraft.light.new("/controls/wiper/frontwiper", [1, 1], wiperSwitchNode);

var wiperStop = func(){
    wiperSwitchNode.setValue(0);
    wiperMode = 0;
}
var wiperFast = func(){
    wiper.pattern = [0.5, 0.5];
    wiperSwitchNode.setValue(1);
    wiperMode = 1;
}
var wiperMid = func(){
    wiper.pattern = [0.7, 0.7];
    wiperSwitchNode.setValue(1);
    wiperMode = 2;
}
var wiperSlow = func(){
    wiper.pattern = [0.7, 2];
    wiperSwitchNode.setValue(1);
    wiperMode = 3;
}
var toggleWiper = func(){
    if(wiperMode == 0){
        wiperSlow();
    }else if(wiperMode == 1){
        wiperStop();
    }else if(wiperMode == 2){
        wiperFast();
    }else if(wiperMode == 3){
        wiperMid();
    }
}
wiper.stateN = wiper.node.initNode("state", 0, "DOUBLE");
props.getNode("/",1).setValue("/controls/wiper/frontwiper_switch", 0);
#var Led = {
#
#    new: func() { return { parents:[Led] },
#    node: props.getNode("/sim/model/livery/texture",1),
#    blankTexture: "Messages/blanco.png",
#    currentMessage: "",
#    messageHistory : [],
#
#    display: func(content){
#        me.node.setValue(content);
#    },
#
#
#};

var Indicator = {

    #     Usage:                                        #
    #  var leftIndicator = Indicator.new("left");       #
    #  var rightIndicator = Indicator.new("right");     #
    #                                                   #

    type: "",
    new: func(type) { return { parents:[Indicator], type: type}; },
    state: 0,
    switchOn: func(){
        props.getNode("/", 1).setValue("/controls/lighting/indicator-"~me.type, 1);
        me.state = 1;
    },
    switchOff: func(){
        props.getNode("/", 1).setValue("/controls/lighting/indicator-"~me.type, 0);
        me.state = 0;
    },
    isOn: func(){
        return me.state;
    },
    isOff: func(){
        return !me.state;
    },
};

var IndicatorController = {

    #
    #   Usage:
    #       mode:
    #           0:Off
    #           1:Right without led
    #           2:Left without led
    #           3:both without led
    #           4:Right with led
    #           5:Left with led
    #           6:both with led(WIP)
    #       getMode(): Get currrent mode
    #       setMode(mode): Set mode(0,1,2), return 0 if fail
    #
    #

    new: func() { return { parents:[IndicatorController]}; },

    leftIndicator : Indicator.new("left"),
    rightIndicator : Indicator.new("right"),

    leftIndicatorSwitchNode: vInfo.lighting.indicator.leftSwitch,
    rightIndicatorSwitchNode: vInfo.lighting.indicator.rightSwitch,

    mode:0,

    falseLight: 0,

    ledMessage: props.getNode("/sim/model/livery/texture",1),
    ledMessageName: props.getNode("/sim/model/livery/name",1),

    savedMessage:{
        texture: "",
        name: "",
    },

    textureRight: {
        texture:"Messages/right.png",
        name: "Right",
    },
    textureLeft: {
        texture:"Messages/left.png",
        name: "Left",
    },

    saveLedMessage: func(){
        me.savedMessage.texture = me.ledMessage.getValue();
        me.savedMessage.name = me.ledMessageName.getValue();
    },
    getSavedMessage: func(){
        return me.savedMessage;
    },
    clearSavedMessage: func(){
        me.savedMessage.texture = "";
        me.savedMessage.name = "";
    },
    setLedMessage: func(content){
        me.ledMessage.setValue(content.texture or " ");
        me.ledMessageName.setValue(content.name or " ");
    },
    resumeLedMessage: func(){
        if(me.getSavedMessage().name != ""){
            me.setLedMessage(me.getSavedMessage());
            me.clearSavedMessage();
        }
    },

    getMode: func(){
        return me.mode;
    },
    setMode: func(targetMode){
        if(targetMode == 0){
            me.resumeLedMessage();
            me.rightIndicator.switchOff();
            me.leftIndicator.switchOff();
            me.mode = targetMode;
            if(me.falseLight == 1){
                me.setMode(3);
            }
        }else if(targetMode == 1){
            me.resumeLedMessage();
            me.rightIndicator.switchOn();
            me.leftIndicator.switchOff();
            me.mode = targetMode;
        }else if(targetMode == 2){
            me.resumeLedMessage();
            me.rightIndicator.switchOff();
            me.leftIndicator.switchOn();
            me.mode = targetMode;
        }else if(targetMode == 3){
            me.resumeLedMessage();
            me.rightIndicator.switchOn();
            me.leftIndicator.switchOn();
            me.mode = targetMode;
        }else if(targetMode == 4){
            me.resumeLedMessage();
            me.saveLedMessage();
            me.rightIndicator.switchOn();
            me.leftIndicator.switchOff();
            me.setLedMessage(me.textureRight);
            me.mode = targetMode;
        }else if(targetMode == 5){
            me.resumeLedMessage();
            me.saveLedMessage();
            me.rightIndicator.switchOff();
            me.leftIndicator.switchOn();
            me.setLedMessage(me.textureLeft);
            me.mode = targetMode;
        }else if(targetMode == 6){
            me.mode = targetMode;
        }else{
            return 0;
        }
    },

    right_indicator_toggle : func(){
        if(isInternalView()) playAudio('IndicatorEnd.wav');
        if(me.getMode() != 4){
            me.setMode(4);
            me.rightIndicatorSwitchNode.setValue(1);
            me.leftIndicatorSwitchNode.setValue(0);
        }else if(me.getMode() == 4){
            me.setMode(0);
            me.rightIndicatorSwitchNode.setValue(0);
        }
    },
    left_indicator_toggle : func(){
        if(isInternalView()) playAudio('IndicatorEnd.wav');
        if(me.getMode() != 5){
            me.setMode(5);
            me.leftIndicatorSwitchNode.setValue(1);
            me.rightIndicatorSwitchNode.setValue(0);
        }else if(me.getMode() == 5){
            me.setMode(0);
            me.leftIndicatorSwitchNode.setValue(0);
        }
    },

    falseLightOn : func(){
        if(isInternalView()) playAudio("electric_handbrake.wav");
        me.falseLight = 1;
        if(me.mode == 1 or me.mode == 2 or me.mode == 4 or me.mode == 5){
           print("falseLight mode on");
        }else{
            me.setMode(3);
            print("falseLight turned on");
        }

    },
    falseLightOff : func(){
        if(isInternalView()) playAudio("electric_handbrake.wav");
        me.falseLight = 0;
        if(me.mode == 1 or me.mode == 2 or me.mode == 4 or me.mode == 5){
           print("falseLight mode off");
        }else{
            me.setMode(0);
            print("falseLight turned off");
        }
    },
    false_light_toggle : func(){
        if(me.falseLight == 0){
            me.falseLightOn();
        }else if(me.falseLight == 1){
            me.falseLightOff();
        }
    },
};

var indicatorController = IndicatorController.new();

var BrakeController = {
    new: func() { return { parents:[BrakeController]}; },
    leftBrakeNode: props.getNode("/controls/gear/brake-left",1),
    rightBrakeNode: props.getNode("/controls/gear/brake-right",1), # These are the rear brakes since the last FDM update
    parkingBrakeNode: props.getNode("/controls/gear/brake-parking",1),

    applyingFeetBrake: 0,
    _handBrakeIsOn: 0,
    _manualHandBrakeIsPulled: 0,
    leftBrakeValue: 0,
    rightBrakeValue: 0,
    
    #//Decides how much brakings to be applied, can be adjusted via GUI and defaults to be 0.8
    keyboardBrakeIntensity: Variable.new("keyboardBrakeIntensity", 0.8, 
                                          "Braking Intensity when using s key", 
                                          0, 1, 1, 
                                          "/systems/BrakeController/keyboardBrakeIntensity"), 

    _applyLeftBrake: func(value){
        # For internal use
        me.leftBrakeNode.setValue(value);
        me.leftBrakeValue = value;
    },
    _applyRightBrake: func(value){
        # For internal use
        me.rightBrakeNode.setValue(value);
        me.rightBrakeValue = value;
    },
    _applyBrakes: func(value){
        # For internal use
        me.rightBrakeNode.setValue(value);
        me.rightBrakeValue = value;
        me.leftBrakeNode.setValue(value);
        me.leftBrakeValue = value;
    },
    applyBrakes: func(value){
        me._applyBrakes(value);
    },
    applyFeetBrakes: func(value){
        # For feet brakes
        if(value) me.applyingFeetBrake = 1;
        else me.applyingFeetBrake = 0;
        me.rightBrakeNode.setValue(value);
        me.rightBrakeValue = value;
        me.leftBrakeNode.setValue(value);
        me.leftBrakeValue = value;
        # Double blink when applying full brakes, should look for a better solution
        if(value == 1) settimer(func{if(me.applyingFeetBrake) safety.emergencyMode();}, 0.6);
    },

    manualHandBrakePull: func(){
        me._manualHandBrakeIsPulled = 1;
        # Right Brakes are the rear brakes since the last FDM update
        me._applyRightBrake(1); 
    },

    manualHandBrakeRelease: func(){
        me._manualHandBrakeIsPulled = 0;
        # Right Brakes are the rear brakes since the last FDM update
        me._applyRightBrake(0);
    },

    _activeHandBrake: func(){
        # for internal use
        me._handBrakeIsOn = 1;
        if(isInternalView()) playAudio("handbrake_on.wav");
        settimer(func(){ #Delay for 0.5 seconds
            me.parkingBrakeNode.setValue(1);
        }, 0.5);
    },
    _deactiveHandBrake: func(){
        # for internal use
        me._handBrakeIsOn = 0;
        if(isInternalView()) playAudio("handbrake_off.wav");
        settimer(func(){ #Delay for 0.5 seconds
            me.parkingBrakeNode.setValue(0);
        }, 0.5);
    },
    enableHandBrake: func(){
        # enable handbrake from button
        if(!me._handBrakeIsOn){
            me._activeHandBrake();
        }
    },
    disableHandBrake: func(){
        # disable handbrake from button
        if(me._handBrakeIsOn){
            me._deactiveHandBrake();
        }
    },
    toggleHandBrake: func(){
        # Toggle handbrake from button
        if(isInternalView()) playAudio("electric_handbrake.wav");
        if(!me._handBrakeIsOn){
            me.enableHandBrake();
        }else{
            me.disableHandBrake();
        }
    },
    activeEmergencyBrake: func(){
        me._applyLeftBrake(1);
        me._applyRightBrake(1);
        me.enableHandBrake();
        safety.emergencyMode();
    },
    keyboardBrake: func(){
        me.applyFeetBrakes(me.keyboardBrakeIntensity.getValue());
    },
    keyboardBrakeRelease: func(){
        me.applyFeetBrakes(0);
        if(vInfo.getSpeedKMH() > 10 and safety.emergencyModeState) safety.disableEmergencyMode();
    },
    releaseBrake: func(){
        me._applyLeftBrake(0);
        me._applyRightBrake(0);
    },
    releaseAllBrakes: func(){
        me._applyLeftBrake(0);
        me._applyRightBrake(0);
        me.disableHandBrake();
    },
    handBrakeIsOn: func(){
        return me._handBrakeIsOn;
    },
    manualHandBrakeIsPulled: func(){
        return me._manualHandBrakeIsPulled;
    },
};

var brakeController = BrakeController.new();

var chargeBatterySec = func(){
    #//var battery = props.getNode("/systems/electrical/e-tron/battery-kWs");
    #//var currentBattery = battery.getValue();
    var battery = circuit_1.parallelConnection[0].units[0];
    var batteryRemaining = battery.remaining;
    var batteryElecForce = battery.ratedElectromotiveForce;
    if(batteryRemaining >= battery.electricalCapacity){
        screen.log.write("Battery is Successfully recharged!", 0, 0.584, 1);
        chargeBatteryStop(batteryElecForce);
    }
    #//battery.setValue(currentBattery+240);
    #//batteryRemaining += 240;
    circuit_1.parallelConnection[0].units[0].addToBattery(240);
}
var chargeTimer = maketimer(1, chargeBatterySec);
var chargeBatteryStart = func(){
    var battery = circuit_1.parallelConnection[0].units[0];
    var batteryRemaining = battery.remaining;
    var batteryTotal = battery.electricalCapacity;
    var batteryElecForce = battery.electromotiveForce;
    if(!props.getNode("/controls/is-recharging", 1).getValue()){
        if(props.getNode("/",1).getValue("services/service-truck/connect") == 1 and props.getNode("/",1).getValue("/controls/engines/engine/started") == 0){
            var deltaBattery = batteryTotal - batteryRemaining;
            battery.electromotiveForce = 0;
            var remainingTime = sprintf("%.0f", (deltaBattery / 240) / 60);      #Based on 20 mins from 0 to full
            screen.log.write("Recharging. About "~remainingTime~" mins remaining.", 0, 0.584, 1);
            setprop("/sim/sound/voices/pilot", "Recharging. About "~remainingTime~" mins remaining.");
            chargeTimer.start();
            props.getNode("/controls/is-recharging", 1).setValue(1);
        }else if(!props.getNode("/",1).getValue("services/service-truck/connect")){
            screen.log.write("Cannot recharge. Call service truck and connect the cable first.", 0, 0.584, 1);
            setprop("/sim/sound/voices/pilot", "Cannot recharge. Call service truck and connect the cable first.");
        }else if(props.getNode("/",1).getValue("/controls/engines/engine/started")){
            screen.log.write("Cannot recharge. Shut down the engine first.", 0, 0.584, 1);
            setprop("/sim/sound/voices/pilot", "Cannot recharge. Shut down the engine first.");
        }
    }else if(props.getNode("/controls/is-recharging", 1).getValue()){
        chargeBatteryStop(batteryElecForce);
    }
}
var chargeBatteryStop = func(bef){
   chargeTimer.stop();
   circuit_1.parallelConnection[0].units[0].electromotiveForce = bef;
   screen.log.write("Recharge Stopped", 0, 0.584, 1);
   setprop("/sim/sound/voices/pilot", "Recharge Stopped. Have a nice ride!");
   props.getNode("/controls/is-recharging", 1).setValue(0);
}

var calculateSpeed = func(){
    var speedKmh = vInfo.getSpeedKMH();
    var calculated = 0;
    var output = 0;
    if(speedKmh <= 0){
        calculated = speedKmh * -1;
    }else if(speedKmh < 280){
        calculated = speedKmh;
    }else if(speedKmh >= 280){
        calculated = 280;
    }

    if(calculated <= 120){
        output = calculated * 1.5; #// 1.5: 3/2
    }else if(calculated > 120){
        output = calculated * 0.75; #// 0.75: 3/4
    }

    props.getNode("systems/display-speed", 1).setValue(output);
}
var calculateSpeedTimer = maketimer(0.1, calculateSpeed);

var resetOnPosition = func(){
    var lat = props.getNode("/position/latitude-deg").getValue();
    var lon = props.getNode("/position/longitude-deg").getValue();
    #// Clear the other presets to prevent issues
    props.getNode("/sim/presets/carrier").setValue("");
    props.getNode("/sim/presets/parkpos").setValue("");
    props.getNode("/sim/presets/airport-id").setValue("");
    props.getNode("/sim/presets/runway").setValue("");
    props.getNode("/sim/presets/runway-requested").setValue(0);
    props.getNode("/sim/presets/altitude-ft").setValue("-9999");
    props.getNode("/sim/presets/airspeed-kt").setValue(0);
    #// Set the latlon in the presets
    props.getNode("/sim/presets/latitude-deg").setValue(lat);
    props.getNode("/sim/presets/longitude-deg").setValue(lon);
    fgcommand("reposition");

    #//The old method, kept for educational purposes
    #//var groundAlt = props.getNode("/position/ground-elev-ft").getValue();
    #//setprop("/fdm/jsbsim/simulation/reset", 1); #This will position the aircraft back to the initial spawn point
    #//props.getNode("/position/altitude-ft").setValue(groundAlt+7);
    #latProp.setValue(lat);
    #lonProp.setValue(lon);
}

var brakesABS = func(){
    var gearFrtLftSpeed = math.round(props.getNode("/",1).getValue("/fdm/jsbsim/gear/unit/wheel-speed-fps"));
    var gearFrtRgtSpeed = math.round(props.getNode("/",1).getValue("/fdm/jsbsim/gear/unit[1]/wheel-speed-fps"));
    var gearBckLftSpeed = math.round(props.getNode("/",1).getValue("/fdm/jsbsim/gear/unit[2]/wheel-speed-fps"));
    var gearBckRgtSpeed = math.round(props.getNode("/",1).getValue("/fdm/jsbsim/gear/unit[3]/wheel-speed-fps"));
    if(gearFrtLftSpeed == 0 or gearBckLftSpeed == 0 or gearFrtRgtSpeed == 0 or gearBckRgtSpeed == 0){
        safety.emergencyMode();
        props.getNode("/",1).setValue("/controls/gear/brake-left", 0);
        props.getNode("/",1).setValue("/controls/gear/brake-right", 0);
    }else{
        props.getNode("/",1).setValue("/controls/gear/brake-left", 1);
        props.getNode("/",1).setValue("/controls/gear/brake-right", 1);
    }
}

var parkingRadar = Radar.new(0.3, 0, 3.8, 3, 3);
var isParkingRadarActive = Variable.new("isParkingRadarActive", 0, "Indicates the status of the parking radar", 0, 1, 0, "/systems/isParkingRadarActive");
var toggleParkingRadar = func(){
    parkingRadar.toggle();
    isParkingRadarActive.setValue(parkingRadar.isRunning);
}

var Safety = {
    new: func(airbagAccelerationLimit=140, sideAirbagAccelerationLimit=75){
        var newSafety = { parents:[Safety] };
        newSafety.airbagAccelerationLimit = airbagAccelerationLimit;
        newSafety.sideAirbagAccelerationLimit = sideAirbagAccelerationLimit;
        newSafety.frontRadar = Radar.new(0.3, 0, 0, 15, 0.1, 180, 0, 0.001);#For AEB
        newSafety.absTimer = maketimer(0.001, brakesABS);
        newSafety.aebTimer = maketimer(0.001, func newSafety.aebUpdate());
        return newSafety;
    },
    isOn: 0,
    isEnabled: 1,
    safetySystemTimer: nil,
    updateInterval: 0.01,
    aebEnabled: 0,
    aebActivated: 0,
    lastRadarOutput:10000,
    throttleNode: vInfo.engine.throttleNode,
    emergencyModeState: 0,
    #Airbag
    accXProp: props.getNode("/fdm/jsbsim/accelerations/a-pilot-x-ft_sec2", 1),
    accYProp: props.getNode("/fdm/jsbsim/accelerations/a-pilot-y-ft_sec2", 1),
    frontAirbagProp: props.getNode("/systems/safety/airbag/front", 1),
    sideAirbagProp: props.getNode("/systems/safety/airbag/side", 1),
    aebStateProp: props.getNode("/systems/safety/aeb_activated", 1),
    aebOnProp: props.getNode("/systems/safety/aeb_on", 1),
    airbagAccelerationLimit: 140, #To be configured,m/s^2
    sideAirbagAccelerationLimit: 75, #To be configured,m/s^2

    #Frontwards radar
    frontRadar: nil,

    enableAEB: func(){
        #Enables the front radar
        me.aebTimer.start();
        me.aebEnabled = 1;
        me.frontRadar.initWithoutStarting();
        #//me.frontRadar.stop();
        me.aebOnProp.setIntValue(1);
        print("AEB enabled");
    },
    disableAEB: func(){
        #Disables the front radar
        me.aebTimer.stop();
        if(me.aebEnabled) me.frontRadar.stop();
        me.aebEnabled = 0;
        me.aebOnProp.setIntValue(0);
        print("AEB disabled");
    },
    toggleAEB: func(){
        if(!me.aebEnabled){
            me.enableAEB();
            playAudio(file: "parking_radar_init.wav", queue: "fx_aeb");
        }
        else me.disableAEB();
    },

    aebThreshold: 9,
    aebFullThreshold: 8,
    aebMode: 1, #//1: slow mode 2: fast mode
    aebCount: 0,
    aebSlowMode: func(){
        me.frontRadar.maxRange = 10;
        #me.frontRadar.maxWidth = 0.1;
        me.aebThreshold = 10;
        me.aebFullThreshold = 10;
        me.aebMode = 1;
        print("AEB Slow Mode");
    },
    aebFastMode: func(){
        me.frontRadar.maxRange = 20;
        #me.frontRadar.maxWidth = 0.05;
        me.aebThreshold = 20;
        me.aebFullThreshold = 16;
        me.aebMode = 2;
        print("AEB Fast Mode");
    },
    aebJudge: func(){
        if(me.frontRadar.radarOutput <= me.aebThreshold and !me.aebActivated) return 1;
        else return 0;
    },
    aebActive: func(){
        me.aebActivated = 1;
        #engine.engine_1.engineSwitch.switchDisconnect();
        brakeController._applyBrakes(0.8);#//Pre brake
        me.throttleNode.setValue(0);
        me.aebWarning();
        me.aebStateProp.setValue(1);
        print("AEB Activated!");
    },
    aebStop: func(){
        me.aebActivated = 0;
        print("AEB Stopped");
        me.aebStateProp.setValue(0);
        #engine.engine_1.engineSwitch.switchConnect();
        brakeController.releaseAllBrakes();
    },
    aebWarning: func(){
        playAudio(file: "parking_radar_high.wav", queue: "fx_aeb");
        playAudio(file: "parking_radar_high.wav", queue: "fx_aeb");
        playAudio(file: "parking_radar_high.wav", queue: "fx_aeb");
    },
    aebFullBrake: func(){
        brakeController.activeEmergencyBrake();
        #playAudio("parking_radar_high.wav");
        print("AEB Full Brake Activated!");
    },

    aebUpdate: func(){
        #//AEB Loop

        var currentSpeed = vInfo.getSpeedKMH();#In km/h
        var radarOutput = me.frontRadar.radarOutput;
        #print("radar output: " ~ radarOutput);
        #print("last radar output: " ~ me.lastRadarOutput);
        if(me.lastRadarOutput <= radarOutput) me.aebCount += 1;
        else me.aebCount = 0;
        if(radarOutput != 10000) me.lastRadarOutput = radarOutput;
        #var deltaX = me.lastRadarOutput - radarOutput;
        #var reletiveSpeed = 3.6 * (deltaX / me.updateInterval);#In km/h
        #if(reletiveSpeed) print(reletiveSpeed);
        if(currentSpeed > 30 and engine.engine_1.getDirection() == 1){
            #Enable AEB when speed is greater then 30kmh and in D gear
            if(me.aebEnabled){
                if(!me.frontRadar.isRunning) me.frontRadar.start();
                if(currentSpeed >= 48 and me.aebMode == 1) me.aebFastMode();
                else if(currentSpeed < 48 and me.aebMode == 2) me.aebSlowMode();#//Adjust mode dynamically according to speed

                if(me.aebJudge()){
                    me.aebActive();
                    if(me.frontRadar.radarOutput <= me.aebFullThreshold){ #//Phase two of braking
                        me.aebFullBrake();
                    }
                }

                if(me.aebActivated){
                    #if(currentSpeed <= 0 or me.aebCount >= 10) me.aebStop();
                    if(currentSpeed <= 0){
                        me.aebStop();
                        #print("1");
                    }else if(me.aebCount >= 15){
                        me.aebStop();
                        #print("2");
                    }
                }
            }
        }else{
            if(me.aebActivated){
                if(currentSpeed <= 0){
                    me.aebStop();
                    #print("11");
                }else if(me.aebCount >= 15){
                    me.aebStop();
                    #print("22");
                }
            }
            if(me.aebEnabled and me.frontRadar.isRunning) me.frontRadar.stop();
        }
    },

    update: func(){
        #Front airbag
        if(math.abs(me.accXProp.getValue() * FT2M) > me.airbagAccelerationLimit){
            #active Front
            me.frontAirbagProp.setValue(1);
            me.emergencyMode();
        }
        #side airbag
        if(math.abs(me.accYProp.getValue() * FT2M) > me.sideAirbagAccelerationLimit){
            #active side
            me.sideAirbagProp.setValue(1);
            me.emergencyMode();
        }
        #AEB, Automatic Emergency Brake
        #Moved out of the main loop

        #ABS
        #var brakeCmd = props.getNode("/",1).getValue("/controls/gear/brake-left");
        #if(brakeCmd and currentSpeed){
        #    me.absTimer.start();
        #}else{
        #    me.absTimer.stop();
        #}

    },

    emergencyMode: func(){
        print("Safety system emergency mode!");
        me.emergencyModeState = 1;
        indicatorController.setMode(3); #Active malfunction light
        indicatorController.falseLight = 1;
        if(autospeed.autoSpeedTimer.isRunning) autospeed.stopAutoSpeed();
        if(autopilot.road_check_timer.isRunning) autopilot.road_check_timer.stop();
    },
    disableEmergencyMode: func(){
        print("Safety system emergency mode disabled!");
        me.emergencyModeState = 0;
        indicatorController.falseLight = 0;
        indicatorController.setMode(0); #Deactive malfunction light
    },

    reset: func(){
        #resetting stops and disables the safety system
        me.stop();
        me.isEnabled = 0;
        me.frontAirbagProp.setValue(0);
        me.sideAirbagProp.setValue(0);
        me.aebStateProp.setValue(0);
    },
    init: func(){
        #initialize or reinitialize (which re-enables the system if disabled earlier)
        me.frontAirbagProp.setValue(0);
        me.sideAirbagProp.setValue(0);
        me.aebStateProp.setValue(0);
        if(me.safetySystemTimer == nil) me.safetySystemTimer = maketimer(me.updateInterval, func me.update());
        me.safetySystemTimer.start();
        #if(me.aebEnabled) me.enableAEB();
        me.isEnabled = 1;
        me.isOn = 1;
        print("Safety system initialized");
    },
    stop: func(){
        me.isOn = 0;
        me.aebStateProp.setValue(0);
        if(me.aebEnabled) me.disableAEB();
        me.safetySystemTimer.stop();
        print("Safety system stoped");
    },
    toggle: func(){
        if(!me.isOn) me.init();
        else me.stop();
    },
};
var safety = Safety.new(140, 75);

#//Service Staion
io.include("service.nas");
#var stationPath = getprop("sim/aircraft-dir")~'/Models/Service-Station/Service-Staion.ac';
#var stationCoord = geo.aircraft_position();
#var stationCourse = getprop("/orientation/heading-deg");
#stationCoord.apply_course_distance(stationCourse, 100); # Model to be added 100 m ahead
#//var model = geo.put_model(stationPath, stationCoord, stationCourse); # Place the default glider


var reduceRollingFriction = func(){
    print("rolling_friction-coeff reduced to 0.006");
    props.getNode("/",1).setValue("/fdm/jsbsim/gear/unit/rolling_friction_coeff", 0.006);
    props.getNode("/",1).setValue("/fdm/jsbsim/gear/unit[1]/rolling_friction_coeff", 0.006);
    props.getNode("/",1).setValue("/fdm/jsbsim/gear/unit[2]/rolling_friction_coeff", 0.006);
    props.getNode("/",1).setValue("/fdm/jsbsim/gear/unit[3]/rolling_friction_coeff", 0.006);
}

var resumeRollingFriction = func(){
    print("rolling_friction-coeff resumed to 0.06");
    props.getNode("/",1).setValue("/fdm/jsbsim/gear/unit/rolling_friction_coeff", 0.06);
    props.getNode("/",1).setValue("/fdm/jsbsim/gear/unit[1]/rolling_friction_coeff", 0.06);
    props.getNode("/",1).setValue("/fdm/jsbsim/gear/unit[2]/rolling_friction_coeff", 0.06);
    props.getNode("/",1).setValue("/fdm/jsbsim/gear/unit[3]/rolling_friction_coeff", 0.06);
}

#//Testing
var testingProgram_1_Entry = func(){
    autospeed.startAutoSpeed();
    autospeed.targetSpeedChange(100);
    settimer(testingProgram_1, 10);
}

var testingProgram_1 = func(){
    props.getNode("/",1).setValue("/controls/gear/brake-left", 1);
    props.getNode("/",1).setValue("/controls/gear/brake-right", 1);
    props.getNode("/",1).setValue("/controls/gear/brake-parking", 1);
}

var testingProgram_2_Entry = func(){
    autospeed.startAutoSpeed();
    autospeed.targetSpeedChange(100);
    settimer(testingProgram_2, 10);
}

var testingProgram_2 = func(){
    props.getNode("/",1).setValue("/controls/gear/brake-left", 1);
    props.getNode("/",1).setValue("/controls/gear/brake-right", 1);
    #props.getNode("/",1).setValue("/controls/gear/brake-parking", 1);
}

#setlistener("/controls/gear/brake-left", brakeWithABS);
