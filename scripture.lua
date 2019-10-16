-- todo: mod function
-- todo: maxLength property ?
-- todo: scale types
-- todo: rndm only change notes - not other props
--sequence = {steps = {}, location = 0, maxLength = 8}

function init()
  sequences, queue, index1, index2, currentSeq = {{}, {}}, {}, 0, 0, 1
  rndm()
  input[1].mode('change', 1, 0.05, 'rising')
  input[1].change = handleChangeClock
  input[2].mode('change', 1, 0.05, 'rising')
  input[2].change = handleChangeInput2
  print('++++++++++++++++scripture++++++++++++++++')
end

function stepForward(seq, outputA, outputB, index)
  local step = seq[index + 1]
  output[outputA].slew = step.slew
  output[outputA].volts = n2v(step.note)
  output[outputB].action = step.eg
  output[outputB]()
  return (index + 1) % #seq
end

function handleChangeClock(state)
  index1 = stepForward(sequences[1], 1, 2, index1)
  index2 = stepForward(sequences[2], 3, 4, index2)
end

function handleChangeInput2(state) rndm() end

function validateRange(first, last)
  if last < first or first < 1 or last > #getCurrentSeq() then
    print('invalid params') return false
  end
  return true
end

function copyStep(step)
  local newStep = {}
  for key,value in pairs(step) do newStep[key] = value end
  return newStep
end

function parseArgs(args)
  local sequenceLength = #getCurrentSeq()
  local first, last, value = 1, sequenceLength, 1
  if #args >= 3 then first, last, value = args[1], args[2], args[3]
    elseif #args == 2 then first, last, value = args[1], sequenceLength, args[2]
    elseif #args == 1 then value = args[1]
  end
  return {['first'] = first, ['last'] = last, ['value'] = value}
end

function getCurrentSeq() return sequences[currentSeq] end
function setSequence(seq) sequences[currentSeq] = seq end

function generateRandomSequence()
  math.randomseed(time())
  local seq = {}
  local noteOptions = {0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23}
  for i=1,8 do
    local note = noteOptions[math.floor(math.random(1, 14))]
    local step = {note = note, slew = 0, eg = ar()}
    table.insert(seq, step)
  end
  return seq
end

-- user functions to invoke from druid below --
function rndm()
  sequences = {generateRandomSequence(), generateRandomSequence()}
  index1 = 0
  index2 = 0
  show()
end

-- change octaves, default 1 octave up entire sequence
function oct(...)
  local args = parseArgs({...})
  tp(args['first'], args['last'], 12*args['value'])
end

-- transpose, default 1 semitone
function tp(...)
  local args = parseArgs({...})
  local first = args['first']
  local last = args['last']
  local value = args['value']
  local sequence = getCurrentSeq()
  if not validateRange(first, last) then return end
  for i=first,last do
    sequence[i].note = sequence[i].note + value
  end
  show()
end

-- reverse entire sequence or subsequence if first and last provided
function rv(first, last)
  local sequence = getCurrentSeq()
  first = first or 1
  last = last or #sequence
  if not validateRange(first, last) then return end
  local reversed = {}
  local idx = first
  for i=last,first,-1 do
    reversed[idx] = sequence[i]
    idx = idx + 1
  end
  for i=first,last do sequence[i] = reversed[i] end
  show()
end

-- duplicate entire sequence or subsequence if first and last provided
function cp(first, last)
  local sequence = getCurrentSeq()
  first = first or 1
  last = last or #sequence
  if not validateRange(first, last) then return end
  for i=first,last do
    table.insert(sequence, copyStep(sequence[i]))
  end
  show()
end

function setValueOrRange(args, param)
  local sequence = getCurrentSeq()
  if #args >= 3 then
    for i=args[1],args[2] do sequence[i][param] = args[3] end
  elseif #args == 2 then
    sequence[args[1]][param] = args[2]
  elseif #args == 1 then
    for i=1,#sequence do sequence[i][param] = args[1] end
  end
end

-- slew - if only 2 args, slew step at arg1 with value at arg2 - else slew range
function slw(...) setValueOrRange({...}, 'slew') end

-- change step envelope, value is ASL function - if only 2 args, slew step at arg1 with value at arg2 - else slew range
function eg(...) setValueOrRange({...}, 'eg') end

-- move step to different position
function mv(step, pos)
  local sequence = getCurrentSeq()
--  local fn = function()
    step = step or 1
    pos = pos or #sequence
    if sequence[step] == nil or sequence[pos] == nil then print('invalid params') return end
    local stepToMove = sequence[step]
    table.remove(sequence, step)
    table.insert(sequence, pos, stepToMove)
    show()
--  end
--  table.insert(queue, fn)
end

-- remove range of notes
function rm(first, last)
  local sequence = getCurrentSeq()
  local sequenceLength = #sequence
--  local fn = function()
    last = last or sequenceLength
    if not validateRange(first, last) then return end
    local newSeq = {}
    if first > 1 then
      for i=1,first - 1 do table.insert(newSeq, sequence[i]) end
    end
    for i=last+1,sequenceLength do table.insert(newSeq, sequence[i]) end
--    if index > #newSeq then index = 0 end
    setSequence(newSeq)
    show()
--  end
--  table.insert(queue, fn)
end

function edit(seq) if seq == 1 or seq == 2 then currentSeq = seq end end

function show()
  for i=1,2 do
    local sequence = sequences[i]
    local seq = 'sequence ' .. i .. ': '
    for j=1,#sequence do seq = seq .. sequence[j].note .. ' ' end
    print(seq)
  end
end
