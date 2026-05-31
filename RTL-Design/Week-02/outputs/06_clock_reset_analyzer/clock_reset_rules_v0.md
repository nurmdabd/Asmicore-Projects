# Clock Reset Analysis Rules v0.1

## Clock Detection

role == "clock"

## Reset Detection

role == "reset"

## Reset Polarity

*_n -> active_low

*_b -> active_low

otherwise -> active_high

## Reset Type

Reset present in sensitivity list
    -> asynchronous

Sequential blocks only
    -> synchronous

No sequential blocks
    -> combinational_only

## Limitation

IR schema v0.1 does not preserve procedural assignments.

Register reset values are unavailable.