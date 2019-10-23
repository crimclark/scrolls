function init()
  scales = {
    ['diatonic'] = {0,2,4,5,7,9,11,12,14,16,17,19,21,23},
    ['pent_major'] = {0,2,4,7,9,12,14,16,19,21},
  }
  semitonesMaj, defaultLn = {2,2,1,2,2,2,1}, 8
  count, div, currentLoop, fnIds, prevSeq, queueLocations = {1,1}, {1,2}, {0,0}, {0,0}, {{},{}}, {1,1}
  sequences, queues, seqLocations, currentSeq, scale = {{}, {}}, {{}, {}}, {0,0}, 1, 'pent_major'
  sequences = {randomizeNotes(sequences[1]), randomizeNotes(sequences[2])}
  for i=1,2 do input[i].mode('change', 1, 0.05, 'rising') end
  input[1].change = handleChangeClock
  input[2].change = handleChangeInput2
end

function handleChangeClock(s)
  for i=1,2 do
    count[i] = count[i] % div[i] + 1
    if count[i] == 1 then handleNewStep(i) end
  end
end

function handleChangeInput2(s)
  sequences = {randomizeNotes(sequences[1]), randomizeNotes(sequences[2]) }
  reset()
end

function handleNewStep(i)
  if seqLocations[i] == 1 then handleSeqStart(i) end
  seqLocations[i] = stepForward(sequences[i], 1%i+i, 1%i+i+1, seqLocations[i])
end

function stepForward(seq, outputA, outputB, index)
  if not seq[index+1].mute then
    output[outputA].slew = seq[index+1].slew
    output[outputA].volts = n2v(seq[index+1].note)
    output[outputB].action = seq[index+1].eg
    output[outputB]()
  end
  return (index+1) % #seq
end

function handleSeqStart(i)
  if #prevSeq[i] > 0 and queueLocations[i] > #queues[i] then
    sequences[i] = prevSeq[i]
    queueLocations[i] = 1
  end
  local queueLoc = queueLocations[i]
  if #queues[i] > 0 then
    if #prevSeq[i] == 0 then prevSeq[i] = sequences[i] end
    if currentLoop[i] <= queues[i][queueLoc].count then doQueuedAction(i, queueLoc) end
    if queues[i][queueLoc].count == -1 then loopAction(i, queueLoc) end
  end
end

function doQueuedAction(i, queueLoc)
  if queues[i][queueLoc].id ~= fnIds[i] then
    fnIds[i] = queues[i][queueLoc].id
    sequences[i] = queues[i][queueLoc].fn(copySeq(prevSeq[i]))
  end
  currentLoop[i] = currentLoop[i]+1
  if currentLoop[i] == queues[i][queueLoc].count then
    queueLocations[i] = queueLoc+1
    currentLoop[i] = 0
  end
end

function loopAction(i, queueLoc)
  sequences[i] = queues[i][queueLoc].fn(copySeq(prevSeq[i]))
  queues[i] = {queues[i][queueLoc]}
  queueLocations[i] = queueLoc+1
end

function copySeq(seq)
  local newSeq = {}
  for _,step in ipairs(seq) do
    local newStep = {}
    for k,v in pairs(step) do newStep[k] = v end
    table.insert(newSeq, newStep)
  end
  return newSeq
end

function parseArgs(args)
  local first, last, value = 1, #sequences[currentSeq], 1
  if #args >= 3 then first, last, value = args[1], args[2], args[3]
    elseif #args == 2 then first, last, value = args[1], #sequences[currentSeq], args[2]
    elseif #args == 1 then value = args[1]
  end
  return {first = first, last = last, value = value}
end

function randomizeNotes(seq)
  math.randomseed(time())
  local length = #seq > 0 and #seq or defaultLn
  for i=1,length do
    local mute = math.random(4) == 1 and true or false
    if not seq[i] then seq[i] = {slew = 0, eg = ar(), mute = mute} end
    seq[i].note = scales[scale][math.floor(math.random(1, #scales[scale]))]
    table.insert(seq, step)
  end
  return seq
end

function findScaleDegree(note)
  while note < 0 do note = note + 12 end
  if note == 0 then return 1 end
  local sum = 0
  while true do
    local semitones = semitonesMaj
    for i=1,#semitones do
      sum = sum + semitones[i]
      if sum == note then return i + 1 end
      if sum > note then print('note ' .. note .. ' not in scale') return end
    end
  end
end

function findIntervalNote(startNote, interval)
  local semitones = semitonesMaj
  local intervalNote = startNote
  if interval >= 0 then
    for i=0,interval-2 do
      intervalNote = intervalNote + semitones[(i+findScaleDegree(startNote)-1) % #semitones+1]
    end
  elseif interval < 0 then
    for i=1,math.abs(interval+1) do
      intervalNote = intervalNote-semitones[(findScaleDegree(startNote)-i-1) % #semitones+1]
    end
  end
  return intervalNote
end

function reset() seqLocations = {0, 0} end

function setValueOrRange(args, param)
  local seq = #prevSeq[currentSeq] > 0 and prevSeq[currentSeq] or sequences[currentSeq]
  if #args >= 3 then for i=args[1],args[2] do seq[i][param] = args[3] end
  elseif #args == 2 then seq[args[1]][param] = args[2]
  elseif #args == 1 then for i=1,#seq do seq[i][param] = args[1] end
  end
end

function sync(a)
  if not a then a = 1 end
  if a ~= 1 and a ~= 2 then return end
  local b = a == 1 and 2 or 1
  sequences[b] = copySeq(sequences[a])
end

function updateQueue(fn, count)
  table.insert(queues[currentSeq], {fn = fn, count = count or 1, id = time()})
  return fn
end

function s(seq)
  seq = seq or currentSeq
  prevSeq[seq] = sequences[seq]
  ptrn()
end

function rndm()
  return updateQueue(function(seq) return randomizeNotes(seq) end, -1)
end

function ptrn(...)
  local newQueue = {}
  for i,v in ipairs({...}) do
    local count = v[2] or 1
    table.insert(newQueue, {fn = v[1], count = count, id = time()+i})
  end
  queues[currentSeq] = newQueue
  queueLocations[currentSeq] = 1
end

function oct(...)
  local args = parseArgs({...})
  return updateQueue(function(seq)
    for i=args.first,args.last do seq[i].note = seq[i].note + args.value*12 end
    return seq
  end, -1)
end

function mod(...)
  local args = parseArgs({...})
  return updateQueue(function(seq)
    for i=args.first,args.last do seq[i].note = findIntervalNote(seq[i].note, args.value) end
    return seq
  end, -1)
end

function rv(first, last)
  return updateQueue(function(seq)
    first = first or 1
    last = last or #seq
    local reversed = {}
    local idx = first
    for i=last,first,-1 do
      reversed[idx] = seq[i]
      idx = idx+1
    end
    for i=first,last do seq[i] = reversed[i] end
    return seq
  end, -1)
end

function slw(...) setValueOrRange({...}, 'slew') end
function eg(...) setValueOrRange({...}, 'eg') end

function mv(step, pos)
  return updateQueue(function(seq)
    step = step or 1
    table.remove(seq, step)
    table.insert(seq, pos or #seq, seq[step])
    return seq
  end, -1)
end

function rm(first, last)
  return updateQueue(function(seq)
    local newSeq = {}
    if first > 1 then for i=1,first-1 do table.insert(newSeq, seq[i]) end end
    for i=(last or #seq)+1,#sequences[currentSeq] do table.insert(newSeq, seq[i]) end
    return newSeq
  end, -1)
end

function ed(seq)
  if not seq then currentSeq = currentSeq%2 + 1 return end
  if seq == 1 or seq == 2 then currentSeq = seq end
end

function shw()
  for i=1,2 do
    local seq = 'sequence ' .. i .. ': '
    for j=1,#sequences[i] do seq = seq .. sequences[i][j].note .. ' ' end
    print(seq)
  end
end

