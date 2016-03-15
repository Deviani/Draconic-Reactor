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
<<<<<<< HEAD
	inputFluxGate = peripheral.wrap("flux_gate_0")
	outputFluxGate = peripheral.wrap("flux_gate_1")
	mon = peripheral.wrap(find("monitor"))
	
	--placeholders need to be tweaked by experimenting with the reactor
	timestep = 50
=======
	inputFluxGate = peripheral.wrap(find("flux_gate_0"))
	outputFluxGate = peripheral.wrap(find("flux_gate_1"))
	mon = peripheral.wrap(find("monitor"))
	
	
	--placeholders need to be tweaked by experimenting with the reactor
	timestep = 100
>>>>>>> aba9da4427916d4450bfd1237dd85420503aeafb
	integral = 0
	
	
	--input controller parameters
<<<<<<< HEAD
	maxInputValue = 500000
	contStrTarget = 50000000
=======
	maxInputValue = 700000
	contStrTarget = 30000000
>>>>>>> aba9da4427916d4450bfd1237dd85420503aeafb
	inputKP = 1
	inputKI = 0.001
	inputKD = 1
	inputFluxGate.setSignalLowFlow(10000)
	
<<<<<<< HEAD
	--initilize variables
	inputIntegral = 0
	inputDerivate = 0
	outputIntegral = 0
	outputDerivate = 0
	preInputError = 0
	preOutputError = 0
	outputValue = 0
	
	--output controller parameters
	maxOutputValue = 600000
	eSatTarget=300000000
	outputKP = 1
=======
	
	--output controller parameters
	maxOutputValue = 700000
	eSatTarget=50000000
	outputKp = 1
>>>>>>> aba9da4427916d4450bfd1237dd85420503aeafb
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
	contDrain = rInfo["fieldDrainRate"]
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
<<<<<<< HEAD
	mon.write("Containtment Strain = " .. contDrain .. " RF/t")
	line(8)
	mon.write("Net = " ..(genRate - contDrain) .. " RF/t")
	line(10)
end

function regulateInput()
	-- Reactor startup
	if rInfo["status"] == "charging" then
		inputFluxGate.setSignalLowFlow(300000)
		return
	elseif rInfo["status"] == "charged" then
		reactor.activateReactor()
	end
	
	--sets the value of the input gate of the reactor.
	--call this function each time step to regulate the input level of the reactor
	inputError = contStrTarget - contStr

	inputIntegral = inputIntegral + (inputError * timestep)
	inputDerivate = (inputError - preInputError) / timestep

	--set the actual value on the flow gate
	inputValue = (inputKP * inputError) + (inputKI * inputIntegral) + (inputKD * inputDerivate)
	print("Input: " .. inputValue)
	
	if inputValue < 0 then
		inputValue = 0
	elseif inputValue > maxInputValue then
		inputValue = maxInputValue
	end
	
	inputFluxGate.setSignalLowFlow(inputValue)
	
	-- to ease it down, so it doesn't take too long to get back to 0 input value
	--if contStrTarget > 5000000 and inputValue > 0 then
		--contStrTarget = contStrTarget - 100000
	--end
	
	contStrTarget = 5000000
		
=======
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
	else if inputValue > maxInputValue
		inputValue = maxInputValue
	end
	
>>>>>>> aba9da4427916d4450bfd1237dd85420503aeafb
	--save the error for next cycle
	preInputError = inputError
end
	
<<<<<<< HEAD
function regulateOutput()
	-- Reactor Heat up
	if tmp < 7500 then
		outputFluxGate.setSignalLowFlow(maxOutputValue)
		return
	end

	--sets the value of the output gate of the reactor.
	--call this function each time step to regulate the output level of the reactor
	outputError = eSatTarget - eSat 
=======

function regulateOutput()
	--sets the value of the output gate of the reactor.
	--call this function each time step to regulate the output level of the reactor
	outputError = contStrTarget - contStr
>>>>>>> aba9da4427916d4450bfd1237dd85420503aeafb
	outputIntegral = outputIntegral + (outputError * timestep)
	outputDerivate = (outputError - preOutputError) / timestep
	
	--set the actual value on the flow gate
<<<<<<< HEAD
	outputValue = ((outputKP * outputError) + (outputKI * outputIntegral) + (outputKD * outputDerivate)) * -1
	
	print("Output: " .. outputValue)
	if outputValue < 0 then
		outputValue = 0
	elseif outputValue > maxOutputValue then
=======
	outputValue = (outputKP * outputError) + (outputKI * outputIntegral) + (outputKD * outputDerivate);
	if outputValue < 0 then
		outputValue = 0
	else if outputValue > maxOutputValue
>>>>>>> aba9da4427916d4450bfd1237dd85420503aeafb
		outputValue = maxOutputValue
	end
	outputFluxGate.setSignalLowFlow(outputValue)
	
<<<<<<< HEAD
	outputFluxGate.setSignalLowFlow(outputValue)
	
=======
>>>>>>> aba9da4427916d4450bfd1237dd85420503aeafb
	--save the error for next cycle
	preOutputError = outputError
end


function safety()
<<<<<<< HEAD
	eText = "Reactor Running"
	--checks all safety constraints of the controller
	if tmp > 8000 then
=======
	--checks all safety constraints of the controller
	if tmp > 7777 then
>>>>>>> aba9da4427916d4450bfd1237dd85420503aeafb
		eText = "Reactor too hot"
		reactor.stopReactor()
		stopped = true
	end
	
	if fConv >= 95 then
		eText = "Reactor needs to refuel"
		reactor.stopReactor()
		stopped = true
	end
	
	if tmp < 2000 and fConv <= 95 then
		reactor.chargeReactor()
		eText = "Charging reactor"
	end
	
	mon.write(eText)
end

function run()
	initializeController()
	while true do
<<<<<<< HEAD
		-- debug
		term.clear()
		term.setCursorPos(1,1)
		
		getInfo()
		regulateInput()
		regulateOutput() 
		formatDisplay()
=======
		getInfo()
		formatDisplay()
		regulateInput()
		--TODO uncomment to allow output to be regulated
		--use fixed output until input parameters are stabilized
		--regulateOutput() 
		gate()
>>>>>>> aba9da4427916d4450bfd1237dd85420503aeafb
		safety()
		sleep(timestep / 1000)
		cls()
	end
end

run()
<<<<<<< HEAD
=======




>>>>>>> aba9da4427916d4450bfd1237dd85420503aeafb
