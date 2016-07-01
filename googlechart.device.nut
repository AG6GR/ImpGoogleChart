#require "APDS9007.class.nut:2.2.1" 
#require "LPS25H.class.nut:2.0.1"
#require "Si702x.class.nut:1.0.0"

local ledPin = hardware.pin2;
ledPin.configure(DIGITAL_OUT);
ledPin.write(1);
local isLEDOn = true;

local lightOutputPin = hardware.pin5;
lightOutputPin.configure(ANALOG_IN);
local lightEnablePin = hardware.pin7;
lightEnablePin.configure(DIGITAL_OUT, 1);
local lightSensor = APDS9007(lightOutputPin, 47000, lightEnablePin);

hardware.i2c89.configure(CLOCK_SPEED_400_KHZ);
local pressureSensor = LPS25H(hardware.i2c89);

local tempHumidSensor = Si702x(hardware.i2c89);

function toggleLED() {
    if (isLEDOn) {
        isLEDOn = false;
        ledPin.write(0);
    } else {
        isLEDOn = true;
        ledPin.write(1);
    }
}

function readLight(result) {
	if ("err" in result) {
        server.error("An Error Occurred: " + result.err);
    } else {
        //server.log(format("Light Level: %0.2f lux", result.brightness));
        agent.send("Light", result);
    }
    toggleLED();
    lightSensor.read(readLight);
}

function readPressure(result) {
	if ("err" in result) {
        server.error("An Error Occurred: " + result.err);
    } else {
        //server.log(format("Current Pressure: %0.2f hPa", result.pressure));
        agent.send("Pressure", result);
    }
    toggleLED();
    pressureSensor.read(readPressure);
}

function readTempHumid(result) {
	if ("err" in result) {
        server.error("An Error Occurred: " + result.err);
    } else {
        //server.log(format("Current Temperature: %0.2f C", result.temperature));
        agent.send("Temperature", result);
        //server.log(format("Current Humidity: %0.2f", result.humidity));
        agent.send("Humidity", result);
    }
    toggleLED();
    tempHumidSensor.read(readTempHumid);
}

// Init APDS9007 Light Sensor
lightSensor.enable(true);
lightSensor.read(readLight);

// Init LPS25H Pressure Sensor
pressureSensor.softReset();
pressureSensor.enable(true); 
pressureSensor.read(readPressure);

// Init Si702 Weather Sensor
tempHumidSensor.read(readTempHumid);