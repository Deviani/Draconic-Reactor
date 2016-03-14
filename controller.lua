local Increment = 1000
local Threshold = 300000000

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
	inputFluxGate = peripheral.wrap(find("flux_gate_0"))
	outputFluxGate = peripheral.wrap(find("flux_gate_1"))
	mon = peripheral.wrap(find("monitor"))
	
	
	--placeholders need to be tweaked by experimenting with the reactor
	timestep = 100
	integral = 0
	
	
	--input controller parameters
	maxInputValue = 700000
	contStrTarget = 30000000
	inputKP = 1
	inputKI = 0.001
	inputKD = 1
	inputFluxGate.setSignalLowFlow(10000)
	
	
	--output controller parameters
	maxInputValue = 700000
	eSatTarget=50000000
	outputKp = 1
	outputKI = 0.001
	outputKD = 1
	--TODO use fixed value until input parameters are stabilized.
	--outputFluxGate.setSignalLowFlow(10000)
end

function cls()
	--clear the monitor
	mon.clear()
	mon.setCursorPos(1,1)
end

function line(y)
	--go to specified line on the monitor
	mon.setCursorPos(1,y)
end

function getInfo()
	--update reactor internal values
	rInfo = reactor.getReactorInfo()
	
	tmp = rInfo["temperature"]
	eSat = rInfo["energySaturation"]
	contStr = rInfo["fieldStrength"]
	genRate = rInfo["generationRate"]
	fConv = rInfo["fuelConversion"]
	fConvR = rInfo["fuelConversionRate"]
end

function formatDisplay()
	--update the display information
	rfCharge = eSat * 0.0000001
	fieldStr = contStr * 0.000001
	rfDisplay = genRate / 1000
	fuel = (fConv / 10368) *100
	if fConvR == nil then
		fConvR = "Not Running"
	end
	
	line(1)
	mon.write("Reactor temperature = " .. tmp)
	line(2)
	mon.write("Energy saturation = ".. rfCharge .. "%")
	line(3)
	mon.write("Containtment strength = " .. fieldStr .. "%")
	line(4)
	mon.write("Fuel Used = " .. fuel .. "%")
	line(6)
	mon.write("RF production = " .. rfDisplay .. " RF/t")
	line(7)
end




function regulateInput()
	--sets the value of the input gate of the reactor.
	--call this function each time step to regulate the input level of the reactor
	inputError = contStrTarget - contStr
	inputIntegral = inputIntegral + (inputError * timestep)
	inputDerivate = (inputError - preInputError) / timestep
	
	--set the actual value on the flow gate
	inputValue = (inputKP * inputError) + (inputKI * inputIntegral) + (inputKD * inputDerivate);
	if inputValue < 0 then
		inputValue = 0
	else if inputValue > 
	inputFluxGate.setSignalLowFlow(inputValue)
	
	--save the error for next cycle
	preInputError = inputError
end
	

function regulateOutput()
	--sets the value of the output gate of the reactor.
	--call this function each time step to regulate the output level of the reactor
	outputError = contStrTarget - contStr
	outputIntegral = outputIntegral + (outputError * timestep)
	outputDerivate = (outputError - preOutputError) / timestep
	
	--set the actual value on the flow gate
	outputValue = (outputKP * outputError) + (outputKI * outputIntegral) + (outputKD * outputDerivate);
	if outputValue < 0 then
		outputValue = 0
	else if outputValue > 
	outputFluxGate.setSignalLowFlow(outputValue)
	
	--save the error for next cycle
	preOutputError = outputError
end


function safety()
	--checks all safety constraints of the controller
	if tmp > 7777 then
		eText = "Reactor too hot"
		reactor.stopReactor()
		stopped = true
	end
	
	if fConv >= 75 then
		eText = "Reactor needs to refuel"
		reactor.stopReactor()
		stopped = true
	end
	
	if tmp < 2000 then
		reactor.chargeReactor()
		eText = "Charging reactor"
		if contStr >= 50000000 and stopped then
			eText = "Activating reactor"
			reactor.activateReactor()
			stopped = false
		end
	else
		if contStr <= 15000000 then
			eText = "Containtment field too weak"
			reactor.stopReactor()
			stopped = true
			contLow = true
		end
		
		if contStr >= 20000000 and stopped and contLow then
			reactor.activateReactor()
			eText = "Reactor activated (containment)"
			stopped = false
			contLow = false
		end
	end
	
	if eSat <= 15000000 then
		reactor.stopReactor()
		eText = "Energy saturation too low"
		
		stopped = true
	end
	
	if eSat >= 20000000 and stopped then
		reactor.activateReactor()
		eText = "Reactor activated"
		stopped = false
	end
	
	mon.write(eText)
end

function run()
	initializeController()
	while true do
		getInfo()
		formatDisplay()
		regulateInput()
		--TODO uncomment to allow output to be regulated
		--use fixed output until input parameters are stabilized
		--regulateOutput() 
		gate()
		safety()
		sleep(timestep / 1000)
		cls()
	end
end

run()




