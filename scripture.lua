scales = {
  ['diatonic'] = {0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23},
  ['pent_major'] = {0, 2, 4, 7, 9, 12, 14, 16, 19, 21},
}
semitonesMajor = {2, 2, 1, 2, 2, 2, 1}
defaultLength = 8
count = {1, 1}
divs = {1, 2}
currentLoop = {0, 0}
fnIds = {0, 0}
prevSequence = {{}, {}}

function init()
  sequences, queues, seqLocations, currentSeq = {{}, {}}, {{}, {}}, {0, 0}, 1
  scale = 'pent_major'
  rndm()
  input[1].mode('change', 1, 0.05, 'rising')
  input[1].change = handleChangeClock
  input[2].mode('change', 1, 0.05, 'rising')
  input[2].change = handleChangeInput2
  print('++++++++++++++++scripture++++++++++++++++')
end

function stepForward(seq, outputA, outputB, index)
  local step = seq[index+1]
  if not step.mute then
    output[outputA].slew = step.slew
    output[outputA].volts = n2v(step.note)
    output[outputB].action = step.eg
    output[outputB]()
  end
  return (index + 1) % #seq
end

function handleChangeClock(s)
  for i=1,2 do
    count[i] = (count[i] % divs[i]) + 1
    if count[i] == 1 then
      if seqLocations[i] == 1 then
        if #prevSequence[i] > 0 and #queues[i] == 0 then sequences[i] = prevSequence[i] end
        if #queues[i] > 0 and currentLoop[i] <= queues[i][1].count then
          print(#queues[i])
          if #prevSequence[i] == 0 then prevSequence[i] = getCurrentSeq() end
          local fnId = queues[i][1].id
          if fnId ~= fnIds[i] then
            fnIds[i] = fnId
            sequences[i] = queues[i][1].fn()
          end
          currentLoop[i] = currentLoop[i]+1
          if currentLoop[i] == queues[i][1].count then table.remove(queues[i], 1) currentLoop[i] = 0 end
        end
        if #queues[i] > 0 and queues[i][1].count == -1 then
          sequences[i] = queues[i][1].fn()
          table.remove(queues[i], 1)
        end
      end
      local outputA = 1%i + i
      seqLocations[i] = stepForward(sequences[i], outputA, outputA+1, seqLocations[i])
    end
  end
end

function handleChangeInput2(state) rndm() end
function validateRange(first, last)
  if last < first or first < 1 or last > #getCurrentSeq() then print('invalid params') return false end return true
end

function copySeq(seq)
  local newSeq = {}
  for i,v in ipairs(seq) do newSeq[i] = copyStep(v) end
  return newSeq
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
  local noteOptions = scales[scale]
  for i=1,8 do
    local note = noteOptions[math.floor(math.random(1, #noteOptions))]
    local step = {note = note, slew = 0, eg = ar(), mute = mute}
    table.insert(seq, step)
  end
  return seq
end

function randomizeNotes(seq)
  math.randomseed(time())
  local noteOptions, seqLength = scales[scale], #seq
  local length = seqLength > 0 and seqLength or defaultLength
  for i=1,length do
    local mute = math.floor(math.random(0, 3)) == 0 and true or false
    if not seq[i] then seq[i] = {slew = 0, eg = ar(), mute = mute} end
    seq[i].note = noteOptions[math.floor(math.random(1, #noteOptions))]
    table.insert(seq, step)
  end
  return seq
end

function updateQueue(fn, count)
  count = count or 1
  table.insert(queues[currentSeq], {fn = fn, count = count, id = time()})
  return fn
end

function rndm()
  sequences = {randomizeNotes(sequences[1]), randomizeNotes(sequences[2]) }
  reset()
  shw()
end

function ptrn(...)
  local args = {... }
  local newQueue = {}
  for i,v in ipairs(args) do
    local fn = v[1]
    local count = v[2]
    table.insert(newQueue, {fn = fn, count = count, id = time()+i})
  end
  queues[currentSeq] = newQueue
end

function oct(...)
  local args = parseArgs({...})
  local fn = function() return tp(args['first'], args['last'], 12*args['value']) end;
  updateQueue(fn, -1)
  return fn
end

function mod(value)
  local seq = copySeq(getCurrentSeq())
  local fn = function()
    for i=1,#seq do seq[i].note = findIntervalNote(seq[i].note, value) end
    return seq
  end
  updateQueue(fn, -1)
  return fn
end

function tp(...)
  local args = parseArgs({...})
  local first = args['first']
  local last = args['last']
  local value = args['value']
  local seq = copySeq(getCurrentSeq())
  if not validateRange(first, last) then return end
  for i=first,last do seq[i].note = seq[i].note + value end
--  return seq
end

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
  shw()
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

function slw(...) setValueOrRange({...}, 'slew') end
function eg(...) setValueOrRange({...}, 'eg') end

function mv(step, pos)
  local sequence = getCurrentSeq()
  step = step or 1
  pos = pos or #sequence
  if sequence[step] == nil or sequence[pos] == nil then print('invalid params') return end
  local stepToMove = sequence[step]
  table.remove(sequence, step)
  table.insert(sequence, pos, stepToMove)
  shw()
end

function rm(first, last)
  local sequence = getCurrentSeq()
  local sequenceLength = #sequence
  last = last or sequenceLength
  if not validateRange(first, last) then return end
  local newSeq = {}
  if first > 1 then
    for i=1,first - 1 do table.insert(newSeq, sequence[i]) end
  end
  for i=last+1,sequenceLength do table.insert(newSeq, sequence[i]) end
  setSequence(newSeq)
  shw()
end

function ed(seq)
  if not seq then currentSeq = currentSeq % 2 + 1 return end
  if seq == 1 or seq == 2 then currentSeq = seq end
end

function shw()
  for i=1,2 do
    local sequence = sequences[i]
    local seq = 'sequence ' .. i .. ': '
    for j=1,#sequence do seq = seq .. sequence[j].note .. ' ' end
    print(seq)
  end
end

function findScaleDegree(note)
  while note < 0 do note = note + 12 end
  if note == 0 then return 1 end
  local sum = 0
  while true do
    local semitones = semitonesMajor
    for i=1,#semitones do
      sum = sum + semitones[i]
      if sum == note then return i + 1 end
      if sum > note then print('note ' .. note .. ' not in scale') return end
    end
  end
end

function findIntervalNote(startNote, interval)
  local semitones = semitonesMajor
  local degree = findScaleDegree(startNote)
  local intervalNote = startNote
  if interval >= 0 then
    for i=0,interval-2 do
      local position = (i + degree - 1) % #semitones + 1
      intervalNote = intervalNote + semitones[position]
    end
    return intervalNote
  end
  if interval < 0 then
    for i=1,math.abs(interval + 1) do
      local position = (degree - i - 1) % #semitones + 1
      intervalNote = intervalNote - semitones[position]
    end
    return intervalNote
  end
end

function reset() seqLocations = {0, 0} end

function sync(a)
  if not a then a = 1 end
  if a ~= 1 and a ~= 2 then return end
  local b = a == 1 and 2 or 1
  sequences[b] = {}
  local seqA, seqB = sequences[a], sequences[b]
  for i=1,#seqA do seqB[i] = copyStep(seqA[i]) end
end

