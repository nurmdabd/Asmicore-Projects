# AST to IR Mapping Table

| AST Node | IR Field |
|-----------|-----------|
| Module | modules[] |
| Parameter | modules[].parameters[] |
| Port | modules[].ports[] |
| Signal | modules[].signals[] |
| Instance | modules[].instances[] |
| Assign | modules[].assigns[] |
| Always Block | modules[].always_blocks[] |

## Semantic Enrichment

| Source Field | Added IR Field |
|--------------|----------------|
| Port Name | role |
| Signal Name | role |
| Metadata | statistics |
| FSM States | fsm_hints |
| Instances | hierarchy_hints |