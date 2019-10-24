# scrolls
Livecoding sequencer for monome crow

- input 1: clock
- input 2: trigger - randomize notes
- output 1: melody 1
- output 2: melody 1 envelope
- output 1: melody 2
- output 2: melody 2 envelope

Script will initialize 2 random melodies at different clock divisions. Each sequence step has properties 'note,' 'mute', 'slew' and 'eg.' When you call a function below, it will update the sequence. Updates take effect at the start of the sequence loop, and you can currently only invoke 1 update per cycle.

## Functions:
>
#### `ed(sequenceNumber)`
- edit - Accepts numbers 1 or 2. selects which sequence will be modified when invoking functions below. Defaults as toggle between 1 and 2 if no number passed in.

#### `rndm()`
- randomize current sequence notes. Does not update other step properties `mute`, `slew` or `eg`.

#### `sync(sequenceNumber)`
- edit - Accepts numbers 1 or 2. sets sequence notes for sequence number passed in to same notes as other sequence.

#### ****`oct(first, last, value)`****
 - Transpose sequence steps first through last by value. All arguments optional.
    
    #### examples: 
    - ****oct()**** -- transpose entire sequence up an octave
    - ****oct(-2)**** -- transpose entire sequence down 2 octaves
    - ****oct(4, 2)**** -- transpose steps 4 through the end of sequence up 2 octaves 
    - ****oct(5, 7, -1)**** -- transpose steps 5 - 7 down 1 octave

#### ****`mod(first, last, value)`****
 - same arguments as oct, but transpose steps by scale degree, so if value is 3, every step will be transposed up a relative 3rd within the scale.
    
#### ****`rv(first, last)`****
 - arguments optional. reverse steps first - last. If no args passed in, reverse entire sequence. If only 1 arg passed in, reverse that value through the end. 
    
#### ****`rm(first, last)`****
 - arguments optional. remove steps first - last. If no args passed in, removes entire sequence. If only 1 arg passed in, remove that value through the end. 

#### ****`mv(step, position)`****
 - move step number to position number, which will shift the sequence within that range to the right or left. Step defaults to 1 and position defaults to the end of the sequence if no args are passed in.
 
#### ****`s()`****
 - save current sequence. Script will always store a reference to the original sequence, functions will be relative to that sequence. This way, if you call `oct()` in a loop, it will not continually transpose up 1 octave until it's in a piercing high frequency, but rather pitch it up an octave relative to the original sequence every time. If you call `s()`, it will overwrite the original sequence with what is currently playing (does not work in `ptrn` mode). 
 
#### ****`slw(first, last, value)`****
- slew - first and last arguments optional. 

    #### examples: 
    - ****slw(1)**** -- slew entire sequence by 1
    - ****slw(4, 0.5)**** -- set step 4 slew to 0.5
    - ****slw(6, 8, 0.7)**** -- set steps 6-8 slew to 0.7
    
#### `eg(first, last, value)`
- set envelope - same argument format as `slw`, but value is an asl function like `ar(0.1, 1)`. 

#### `ptrn(action, count, action, count...)`
- create meta sequence with function calls passed in. Each "action" is a function call, and count is the number of loops for that action. Count defaults to 1 if action is not followed by a number. Pattern will loop infinitely until `ptrn()` is called with no args, which will clears the pattern and resets the sequence.

    #### example: 
    - ****ptrn(mod(3), 2, oct(-1), 3, rndm(), rv(), 2)**** -- modulate up a 3rd for 2 loops, transpose down an octave for 3 loops, randomize notes for 1 loop, reverse sequence for 2 loops.
    
## Clock divisions

 - `div[1] = 2` set clock division of sequence 1 to 2
 - `div[2] = 3` set clock division of sequence 2 to 3

