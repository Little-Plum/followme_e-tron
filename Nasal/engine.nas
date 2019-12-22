var Engine = {
    #//Class for any electric engine
    #//mTorque: Max torque, mPower: Max Power, rpmAtMPower: RPM at max power
    #//For this vehicle: maxPower: 375kW
    
    new: func(mTorque, mPower, rpmAtMPower) {
        return { parents:[Engine, followme.Appliance.new()], maxTorque: mTorque, ratedPower:mPower, rpmAtMaxPower:rpmAtMPower }; 
    },
    
    resistance: 0.1, #//No datasource, based on guess
    
    runningState: 0,
    
    engineSwitch: followme.Switch.new(0),
    
    isRunning: func(){
        return me.runningState;
    },
    
    direction: 1,
    setDirection: func(dir){
        me.direction = dir;
    },
    toggleDirection: func(){
        if(me.direction == 1){
            me.direction = -1;
        }else{
            me.direction = 1;
        }
    },
    getDirection: func(){
        return me.direction;
    },
    
    gear: 9.73,
    setGear: func(g){
        me.gear = g;
    },
    getGear: func(){
        return me.gear;
    },
    
    rpm: 0,
    
    maxTorque: 460, #Nm
    
    rpmAtMaxPower: 6150, #rpm
    
    angularSpeed: 0, #rad/s
    torque: 0, #Nm
    outputForce: 0, #N
    
    debugMode: 0,
  
    rpm_calculate: func(angularAcceleration){
        
        var rpm = me.rpm;
        #//var rps = rpm / 60;
        
        
        var angularSpeed = rpm * 0.10471975; #//rps * 2 * 3.1415926
    
        var friction_lbs = props.getNode("/",1).getValue("fdm/jsbsim/forces/fbx-gear-lbs");
        var friction = 4.4492 * friction_lbs;
        #//var frictionTorque = friction * 0.045; 
        var angularDecelaeration = friction * 0.072; #//frictionTorque = friction * 0.15 * 0.3, angularDecelaeration = frictionTorque/0.625;
        #print(angularAcceleration);
        #print("de"~angularDecelaeration);
        
        
        
        angularDecelaeration = math.abs(angularDecelaeration) * me.getDirection() * -1;

        
        
        var totalAcceleration = angularAcceleration + angularDecelaeration;
   
        if(me.getDirection() == 1){
            if(angularSpeed + totalAcceleration * 0.1 > 10){
                angularSpeed = angularSpeed + totalAcceleration * 0.1;
            }else if(angularSpeed + totalAcceleration * 0.1 < 10){
                #print("angularSpeed + totalAcceleration * 0.1 < 10");
                angularSpeed = angularSpeed + angularAcceleration * 0.1;
            }
        }else if(me.getDirection() == -1){
            if(angularSpeed + totalAcceleration * 0.1 < -10){
                angularSpeed = angularSpeed + totalAcceleration * 0.1;
            }else if(angularSpeed + totalAcceleration * 0.1 > -10){
                angularSpeed = angularSpeed + angularAcceleration * 0.1;
            }
        }
   
        #//rps = angularSpeed / 6.2831853;
        rpm = angularSpeed * 9.5492966; #//rps * 60
    
        me.rpm = rpm;
        props.getNode("/",1).setValue("/controls/engines/engine/rpma",rpm);
        me.angularSpeed = angularSpeed;
    
        return rpm;
    },
    
    update_engine: func(){
        var throttle = props.getNode("/",1).getValue("/controls/engines/engine/throttle");
        var direction = me.getDirection();
        var mode = props.getNode("/",1).getValue("/controls/mode");
        var volt = me.voltage;
        
        if(!volt){
            me.rpm = 0;
            props.getNode("/",1).setValue("/controls/engines/engine/rpma", 0);
            outputForce(0);
            return 0;
        }

        throttle = throttle * mode;
        #print("throttle:" ~throttle);
        
        var cmdRpm = throttle * me.rpmAtMaxPower;
        #print("cmdRpm: "~cmdRpm);
        
        var cmdPower = throttle * me.ratedPower;
        #print("cmdPower: "~cmdPower);
        me.activePower_kW = math.abs(me.rpm * me.torque / 10824);
       
        if(math.abs(me.rpm) < cmdRpm){
            #print("me.rpm < cmdRpm");
            me.torque = throttle * me.maxTorque * direction;
            var angularAcceleration = me.torque / 0.175; #rad/s^2
            me.rpm = me.rpm_calculate(angularAcceleration);
        }else if(throttle == 0){
            me.activePower_kW = 0;
            me.torque = 0;
            var angularAcceleration = direction * math.abs(me.torque) / 0.175; #rad/s^2
            me.rpm = me.rpm_calculate(angularAcceleration);
        }else{
            me.activePower_kW = cmdPower;
            var angularAcceleration = direction * math.abs(me.torque) / 0.175; #rad/s^2
            me.rpm = me.rpm_calculate(angularAcceleration);
            me.torque = direction * math.abs(me.activePower_kW / me.rpm * 10824);
        }
    
        var force = 3.33 * me.torque * me.gear;
    
        me.outputForce = force;
        
        if(me.debugMode){
            me.debugPrint();
        }
        
        
        outputForce(me.outputForce);
   
    },
    
    engineTimer: nil,
    
    timerCreated: 0,
    
    createTimer: func(){
        if(!me.timerCreated){
            me.engineTimer = maketimer(0.1, func me.update_engine());
            me.timerCreated = 1;
        }
    },
    
    startEngine: func(){
        me.createTimer();
        me.engineSwitch.switchConnect();
        me.runningState = 1;
        props.getNode("/",1).setValue("/controls/engines/engine/started",1);
        me.engineTimer.simulatedTime = 1;
        me.rpm = 100 * me.getDirection();
        me.engineTimer.start();
        return 1;
    },
    
    stopEngine: func(){
        me.rpm = 0;
        me.torque = 0;
        me.outputForce = 0;
        me.activePower_kW = 0;
        me.runningState = 0;
        me.engineSwitch.switchDisconnect();
        props.getNode("/",1).setValue("/controls/engines/engine/started",0);
        me.engineTimer.stop();
    },
    
    debugPrint: func(){
        print("rpm: "~me.rpm);
        print("torque: "~me.torque);
        print("power: "~me.activePower_kW);
        print("______________________________________________");
    },
    
};


var engine_1 = Engine.new(460, 375, 6150);
followme.circuit_1.addUnitToSeries(0, followme.Cable.new(5, 0.008));
followme.circuit_1.addUnitToSeries(0, engine_1);
followme.circuit_1.addUnitToSeries(0, engine_1.engineSwitch);
engine_1.engineSwitch.switchDisconnect();
followme.circuit_1.addUnitToSeries(0, followme.Cable.new(5, 0.008));

var outputForce = func(force){
    if(props.getNode("/",1).getValue("/fdm/jsbsim/gear/unit/compression-ft") > 0){
        props.getNode("/",1).setValue("/fdm/jsbsim/external_reactions/FL/magnitude", force/4);
    }else{
        props.getNode("/",1).setValue("/fdm/jsbsim/external_reactions/FL/magnitude", 0);
    }
    
    if(props.getNode("/",1).getValue("/fdm/jsbsim/gear/unit[1]/compression-ft") > 0){
        props.getNode("/",1).setValue("/fdm/jsbsim/external_reactions/FR/magnitude", force/4);
    }else{
        props.getNode("/",1).setValue("/fdm/jsbsim/external_reactions/FR/magnitude", 0);
    }
    
    if(props.getNode("/",1).getValue("/fdm/jsbsim/gear/unit[2]/compression-ft") > 0){
        props.getNode("/",1).setValue("/fdm/jsbsim/external_reactions/BL/magnitude", force/4);
    }else{
        props.getNode("/",1).setValue("/fdm/jsbsim/external_reactions/BL/magnitude", 0);
    }
    
    if(props.getNode("/",1).getValue("/fdm/jsbsim/gear/unit[3]/compression-ft") > 0){
        props.getNode("/",1).setValue("/fdm/jsbsim/external_reactions/BR/magnitude", force/4);
    }else{
        props.getNode("/",1).setValue("/fdm/jsbsim/external_reactions/FR/magnitude", 0);
    }
}


var startEngine = func(){
    if(!props.getNode("/controls/is-recharging").getValue()){
        
        if(props.getNode("systems/welcome-message", 1).getValue() == 1){
            props.getNode("/sim/messages/copilot", 1).setValue("Beijing di san tsui jiao tong wei ti xing nin, Dao lu tsian wan tiao, ann tsuan di yi tiao, xing che bull gui fun, tsin ren liang hang lei");
        }else if(props.getNode("systems/welcome-message", 1).getValue() == 2){
            props.getNode("/sim/messages/copilot", 1).setValue("This is a reminder from The Third District Traffic Commission of Beijing. There are thousands of roads, and the safety is the first. If you drive recklessly, your loved ones will be filled with tears.");
        }
        
        var signal = engine_1.startEngine();
        if(signal){
            print("Engine started");
        }
    }else if(followme.chargeTimer.isRunning){
        #screen.log.write("Battery is recharging, cannot start engine.", 0, 0.584, 1);
        setprop("/sim/sound/voices/pilot", "Battery is recharging, cannot start engine.");
    }
}

var stopEngine = func(){
    engine_1.stopEngine();
    print("Engine stopped");
}

