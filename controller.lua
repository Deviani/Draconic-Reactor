local function find( _type )
    for _, name in ipairs( peripheral.getNames() ) do
        if peripheral.getType( name ) == _type then
            return name
        end
    end
end

local function round(num, places)
		if not num then 
			return 
		end
		
        num = tostring(num)
        local inc = false
        local decimal = string.find(num, "%.")
		if not decimal then
			return
		end
        if num:len() - decimal <= places then return tonumber(num) end --already rounded, nothing to do.
        local digit = tonumber(num:sub(decimal + places + 1))
        num = num:sub(1, decimal + places)
        if digit <= 4 then return tonumber(num) end --no incrementation needed, return truncated number
        local newNum = ""
        for i=num:len(), 1, -1 do
                digit = tonumber(num:sub(i))
                if digit == 9 then
                        if i > 1 then
                                newNum = "0"..newNum
                        else
                                newNum = "10"..newNum
                        end
                elseif digit == nil then
                        newNum = "."..newNum
                else
                        if i > 1 then
                                newNum = num:sub(1,i-1)..(digit + 1)..newNum
                        else
                                newNum = (digit + 1)..newNum
                        end
                        return tonumber(newNum) --No more 9s found, so we are done incrementing. Copy remaining digits, then return number.
                end
        end
        return tonumber(newNum)
end

function setMode(mode)
	if mode == "efficent" then
		contStrTarget = 30000000
		eSatTarget=300000000
	elseif mode == "extreme" then
		contStrTarget = 5000000
	else
		mode = "balance"
		contStrTarget = 50000000
		eSatTarget=500000000
	end
end

function initializeController()
	--set up reactor devices
	reactor = peripheral.wrap(find("draconic_reactor"))
	inputFluxGate = peripheral.wrap("flux_gate_0")
	outputFluxGate = peripheral.wrap("flux_gate_1")
	mon = peripheral.wrap(find("monitor"))
--	store = peripheral.wrap(find("draconic_rf_storage"))

	--set initial mode to balanced
	
	
	--placeholders need to be tweaked by experimenting with the reactor
	timestep = 100
	integral = 0
	
	--input controller parameters
	maxInputValue = 700000
	contStrTarget = 5000000
	inputKP = 0.00005
	inputKI = 0.0000022
	inputKD = 0.00044
	inputFluxGate.setSignalLowFlow(10000)
	
	--initilize variables
	inputIntegral = 0
	inputDerivate = 0
	outputIntegral = 0
	outputDerivate = 0
	preInputError = 0
	preOutputError = 0
	outputValue = 0

	--output controller parameters
	maxOutputValue = 700000
	eSatTarget=500000000
	outputKP = 1
	outputKI = 0.0000022
	outputKD = 0.002
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
end

function formatDisplay()
	-- update display values
	rfCharge = eSat * 0.0000001
	fieldStr = contStr * 0.000001
	rfDisplay = genRate / 1000
	fuel = (fConv / 10368) *100
	
	-- update screen text without clearing
	updateLine(1,"Reactor temperature = " .. tmp)
	updateLine(2,"Energy saturation = " .. round(rfCharge,2) .. "%")
	updateLine(3,"Containtment strength = " .. round(fieldStr,2) .. "%")
	updateLine(4,"Fuel Used = " .. round(fuel,2) .. "%")
	updateLine(6,"RF production = " .. rfDisplay .. " RF/t")
	updateLine(7,"Containtment Strain = " .. contDrain .. " RF/t")
	updateLine(8,"Net = " ..(genRate - contDrain) .. " RF/t")
end

function regulateInput()
	-- Reactor startup
	if rInfo["status"] == "charging" then
		inputFluxGate.setSignalLowFlow(400000)
		return
	elseif rInfo["status"] == "charged" then
		reactor.activateReactor()
	end
	
	--sets the value of the input gate of the reactor.
	--call this function each time step to regulate the input level of the reactor
	inputError = contStrTarget - contStr

	inputIntegral = inputIntegral + (inputError * timestep)
	if inputIntegral < 0 then
		inputIntegral = 0
	end
	inputDerivate = (inputError - preInputError) / timestep

	--set the actual value on the flow gate
	inputValue = (inputKP * inputError) + (inputKI * inputIntegral) + (inputKD * inputDerivate)
	print("P-input: " .. (inputKP * inputError))
	print("I-Input: " .. (inputKI * inputIntegral))
	print("D-Input: " .. (inputKD * inputDerivate))
	print("Input: " .. inputValue)
	
	if inputValue < 0 then
		inputValue = 0
	elseif inputValue > maxInputValue then
		inputValue = maxInputValue
	end
	
	inputFluxGate.setSignalLowFlow(inputValue)	
end

function regulateOutput()
	-- Reactor Heat up
	if tmp < 7500 and mode == "extreme" then
		outputFluxGate.setSignalLowFlow(maxOutputValue)
		return
	else
		--sets the value of the output gate of the reactor.
		--call this function each time step to regulate the output level of the reactor
		outputError = eSatTarget - eSat 
		outputIntegral = outputIntegral + (outputError * timestep)
		outputDerivate = (outputError - preOutputError) / timestep
	
		--set the actual value on the flow gate
		outputValue = ((outputKP * outputError) + (outputKI * outputIntegral) + (outputKD * outputDerivate)) * -1

		print("P-output: " .. (outputKP * outputError))
		print("I-output: " .. (outputKI * outputIntegral))
		print("D-output: " .. (outputKD * outputDerivate))
		print(eSat)
		print(eSatTarget)
		print("output: " .. outputValue)
	
		if outputValue < 0 then
			outputValue = 0
		elseif outputValue > maxOutputValue then
			outputValue = maxOutputValue
		end

		outputFluxGate.setSignalLowFlow(outputValue)
	
		--save the error for next cycle
		preOutputError = outputError
	end
end


function safety()
	eText = "Reactor Running"
	--checks all safety constraints of the controller
	if tmp > 7900 then
		eText = "Reactor too hot"
		reactor.stopReactor()
		stopped = true
	end
	
	if fuel >= 90 then
		eText = "Reactor needs to refuel"
		reactor.stopReactor()
		stopped = true
	end
	
	if tmp < 2000 and fuel <= 90 and rInfo["status"] == "offline" then
		reactor.chargeReactor()
		eText = "Charging reactor"
	end
	
	updateLine(10, eText)
end

function run()
	while true do
		-- debug
		term.clear()
		term.setCursorPos(1,1)
		
		getInfo()
		regulateInput()
		regulateOutput() 
		formatDisplay()
		safety()
		sleep(timestep / 1000)
	end
end

-- Set initil values
initializeController()
-- Set Balanced mode
setMode("balanced")
-- Run program loop
run()
