local Increment = 1000
local Threshold = 300000000

local function find( _type )
    for _, name in ipairs( peripheral.getNames() ) do
        if peripheral.getType( name ) == _type then
            return name
        end
    end
end

reactor = peripheral.wrap(find("draconic_reactor"))
fluxGate = peripheral.wrap(find("flux_gate"))
mon = peripheral.wrap(find("monitor"))

function cls()
	mon.clear()
	mon.setCursorPos(1,1)
end

function line(y)
	mon.setCursorPos(1,y)
end

function getInfo()
	rInfo = reactor.getReactorInfo()
	
	tmp = rInfo["temperature"]
	eSat = rInfo["energySaturation"]
	contStr = rInfo["fieldStrength"]
	genRate = rInfo["generationRate"]
	fConv = rInfo["fuelConversion"]
	fConvR = rInfo["fuelConversionRate"]
end

function formatDisplay()
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
	Gate()
end

function Gate()
	lowFlow = fluxGate.getSignalLowFlow()
	
	if eSat > Threshold then
		if lowFlow >= (700000 - Increment) then
			lowFlow = (700000 - Increment)
		end
		
		lowFlow = lowFlow + Increment
		
	else
		if lowFlow < Increment then
			lowFlow = Increment
		end
		
		lowFlow = lowFlow - Increment
	end
	
	mon.write("Flux Gate set to " .. lowFlow .. " RF/t")
	line(9)
	fluxGate.setSignalLowFlow(lowFlow)
end

function safety()
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

while true do
	getInfo()
	formatDisplay()
	safety()
	sleep(0.1)
	cls()
end
