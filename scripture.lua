sequence1, sequence2, queue, index1, index2, currentSeq = {}, {}, {}, 0, 0, 1
sequences = {sequence1, sequence2}

function init()
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
end

function handleChangeClock(state)
  index1 = ((index1 + 1) % #sequence1)
  stepForward(sequence1, 1, 2, index1)
  index2 = ((index2 + 1) % #sequence2)
  stepForward(sequence2, 3, 4, index2)
end

function handleChangeInput2(state) rndm() end

function validateRange(first, last)
  local sequence = getCurrentSeq()
  if last < first or first < 1 or last > #sequence then
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
  local sequence = getCurrentSeq()
  local first, last, value = 1, #sequence, 1
  if #args >= 3 then
    first, last, value = args[1], args[2], args[3]
  elseif #args == 2 then
    first, last, value = args[1], #sequence, args[2]
  elseif #args == 1 then
    value = args[1]
  end
  return {['first'] = first, ['last'] = last, ['value'] = value }
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
  sequence1 = generateRandomSequence()
  sequence2 = generateRandomSequence()
  sequences = {sequence1, sequence2}
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
  local sequence = getCurrentSeq()
  local args = parseArgs({...})
  local first = args['first']
  local last = args['last']
  local value = args['value']
  print(first)
  print(last)
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
    if sequence[step] == nil or sequence[pos] == nil then
      print('invalid params') return
    end
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
--  local fn = function()
    last = last or #sequence
    if not validateRange(first, last) then return end
    local newSeq = {}
    if first > 1 then
      for i=1,first - 1 do
        table.insert(newSeq, sequence[i])
      end
    end
    for i=last+1,#sequence do
      table.insert(newSeq, sequence[i])
    end
--    if index > #newSeq then index = 0 end
    setSequence(newSeq)
    show()
--  end
--  table.insert(queue, fn)
end

-- print selected sequence notes
function show()
  local sequence = getCurrentSeq()
  local seq = ''
  for i=1,#sequence do
    seq = seq .. sequence2[i].note .. ' '
  end
  print(seq)
end
