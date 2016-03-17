local function find( _type )
    for _, name in ipairs( peripheral.getNames() ) do
        if peripheral.getType( name ) == _type then
            return name
        end
    end
end

function initializeController()


	--set up reactor devices
	reactor = peripheral.wrap(find("draconic_reactor"))
	inputFluxGate = peripheral.wrap("flux_gate_0")
	outputFluxGate = peripheral.wrap("flux_gate_1")
	mon = peripheral.wrap(find("monitor"))
--	store = peripheral.wrap(find("draconic_rf_storage"))

	inputValue = inputFluxGate.getSignalLowFlow()
	outputValue = outputFluxGate.getSignalLowFlow()

	--set initial mode to balanced
	
	
	--placeholders need to be tweaked by experimenting with the reactor
	timestep = 10
	integral = 0
end

function updateLine(y,text)
	-- start at specified line
	mon.setCursorPos(1,y)
	maxw, maxh = mon.getSize()
	
	for i = #text, maxw do
		text = text .. " "
	end
	mon.write(text)
end

function getInfo()
	--update reactor internal values
	rInfo = reactor.getReactorInfo()
	
	tmp = rInfo["temperature"]
	eSat = rInfo["energySaturation"]
	contStr = rInfo["fieldStrength"]
	contDrain = rInfo["fieldDrainRate"]
	genRate = rInfo["generationRate"]
	fConv = rInfo["fuelConversion"]
	fConvR = rInfo["fuelConversionRate"]
	
	inputValue = inputFluxGate.getSignalLowFlow()
	outputValue = outputFluxGate.getSignalLowFlow()
end


function initializeMonitor()
	--set up reactor devices
	reactor = peripheral.wrap(find("draconic_reactor"))
	inputFluxGate = peripheral.wrap("flux_gate_0")
	outputFluxGate = peripheral.wrap("flux_gate_1")
	mon = peripheral.wrap(find("monitor"))
	
	timestep = 100
	inputValue = 0
	outputValue = 0

	myoutputhandle = io.open("ReactorMonitorOutput.csv", "w")
	
end


function run()
	initializeMonitor()
	local ouf = assert(io.open("ReactorMonitorOutput.csv", "w"), "Failed to open output file"
	ouf:write("temperature|saturation|fieldStrength|fieldDrainRate|generationRate|fuelConverion|fuelConversionRate|gateInput|gateOutput\r\n"
	while true do
		getInfo()
		ouf:write(tmp .. "|" .. eSat .. "|" .. contStr .. "|" .. contDrain .. "|" .. genRate .. "|" .. fConv .. "|" .. fConvR .. "|" .. inputValue .. "|" .. outputValue  .. "\r\n" .. )
		sleep(timestep / 1000)
	end
end

-- Run program loop
run()
