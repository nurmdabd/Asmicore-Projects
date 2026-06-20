# Kronos Master Matrix With Extra Run

| Count | Metric                         | 500 MHz                           | 600 MHz                           | 700 MHz                           | 1500 MHz                          | 2000 MHz                          |
| :---: | ------------------------------ | --------------------------------- | --------------------------------- | --------------------------------- | --------------------------------- | --------------------------------- |
|   1   | Clock Period (ps)              | 2000                              | 1667                              | 1429                              | 667                               | 500                               |
|   2   | Top Module                     | kronos_core                       | kronos_core                       | kronos_core                       | kronos_core                       | kronos_core                       |
|   3   | RTL Files                      | 13                                | 13                                | 13                                | 13                                | 13                                |
|   4   | Total Cells                    | 13971                             | 13971                             | 13971                             | 13971                             | 13971                             |
|   5   | Combinational Cells            | 12038                             | 12038                             | 12038                             | 12038                             | 12038                             |
|   6   | Sequential Cells               | 1933                              | 1933                              | 1933                              | 1933                              | 1933                              |
|   7   | DFF Count                      | 1933                              | 1933                              | 1933                              | 1933                              | 1933                              |
|   8   | Sequential Cell %              | 13.84%                            | 13.84%                            | 13.84%                            | 13.84%                            | 13.84%                            |
|   9   | Sequential Area (%)            | 33.58%                            | 33.58%                            | 33.58%                            | 33.58%                            | 33.58%                            |
|  10   | Chip Area (um2)                | 1745.852940                       | 1745.852940                       | 1745.852940                       | 1745.852940                       | 1745.852940                       |
|  11   | Worst Slack                    | 1469.73                           | 1136.73                           | 898.73                            | 136.39                            | -30.27                            |
|  12   | WNS (ps)                       | 0.00                              | 0.00                              | 0.00                              | 0.00                              | -30.27                            |
|  13   | TNS (ps)                       | 0.00                              | 0.00                              | 0.00                              | 0.00                              | -77.98                            |
|  14   | FEP                            | 0                                 | 0                                 | 0                                 | 0                                 | 1                                 |
|  15   | Minimum Period (ps)            | 530.26                            | 530.27                            | 530.27                            | 530.27                            | 530.27                            |
|  16   | Estimated Fmax (MHz)           | 1885.85                           | 1885.85                           | 1885.85                           | 1885.85                           | 1885.85                           |
|  17   | Path Groups                    | clk                               | clk                               | clk                               | clk                               | clk                               |
|  18   | Number of Path Groups          | 1                                 | 1                                 | 1                                 | 1                                 | 1                                 |
|  19   | Most Critical Path Group       | clk                               | clk                               | clk                               | clk                               | clk                               |
|  20   | Number of Max Paths            | 2                                 | 2                                 | 2                                 | 2                                 | 2                                 |
|  21   | Start Point                    | `u_if.fetch[2]$`<br>`_DFFE_PP_`   | `u_if.fetch[2]$`<br>`_DFFE_PP_`   | `u_if.fetch[2]$`<br>`_DFFE_PP_`   | `u_if.fetch[2]$`<br>`_DFFE_PP_`   | `u_if.fetch[2]$`<br>`_DFFE_PP_`   |
|  22   | End Point                      | `u_id.decode[50]$`<br>`_DFFE_PP_` | `u_id.decode[50]$`<br>`_DFFE_PP_` | `u_id.decode[50]$`<br>`_DFFE_PP_` | `u_id.decode[50]$`<br>`_DFFE_PP_` | `u_id.decode[50]$`<br>`_DFFE_PP_` |
|  23   | Critical Path Logic Depth      | 19                                | 19                                | 19                                | 19                                | 19                                |
|  24   | Largest Cell Type              | `HAxp5_ASAP7_75t_R`               | `HAxp5_ASAP7_75t_R`               | `HAxp5_ASAP7_75t_R`               | `HAxp5_ASAP7_75t_R`               | `HAxp5_ASAP7_75t_R`               |
|  25   | Largest Cell Delay (ps)        | 62.46                             | 62.46                             | 62.46                             | 62.46                             | 62.46                             |
|  26   | Data Arrival Time (ps)         | 515.19                            | 515.19                            | 515.19                            | 515.19                            | 515.19                            |
|  27   | Setup Time (ps)                | 15.08                             | 15.08                             | 15.08                             | 15.08                             | 15.08                             |
|  28   | VT Type                        | RVT                               | RVT                               | RVT                               | RVT                               | RVT                               |
|  29   | RVT Percentage                 | 100%                              | 100%                              | 100%                              | 100%                              | 100%                              |
|  30   | Internal Power (W)             | 3.14e-03                          | 3.77e-03                          | 4.40e-03                          | 9.43e-03                          | 1.26e-02                          |
|  31   | Switching Power (W)            | 1.21e-03                          | 1.45e-03                          | 1.70e-03                          | 3.63e-03                          | 4.85e-03                          |
|  32   | Leakage Power (W)              | 1.25e-06                          | 1.25e-06                          | 1.25e-06                          | 1.25e-06                          | 1.25e-06                          |
|  33   | Total Power (W)                | 4.35e-03                          | 5.22e-03                          | 6.09e-03                          | 1.31e-02                          | 1.74e-02                          |
|  34   | Sequential Contribution (%)    | 47.3%                             | 47.3%                             | 47.3%                             | 47.3%                             | 47.3%                             |
|  35   | Combinational Contribution (%) | 52.7%                             | 52.7%                             | 52.7%                             | 52.7%                             | 52.7%                             |
|  36   | Buffer Count                   | 1420                              | 1420                              | 1420                              | 1420                              | 1420                              |
|  37   | Inverter Count                 | 779                               | 779                               | 779                               | 779                               | 779                               |
|  38   | Arithmetic Cell Count          | 171                               | 171                               | 171                               | 171                               | 171                               |
|  39   | Average Cell Area              | 0.1250                            | 0.1250                            | 0.1250                            | 0.1250                            | 0.1250                            |
|  40   | Power Density                  | 2.49161880e-06                    | 2.98994255e-06                    | 3.48826631e-06                    | 7.50349568e-06                    | 9.96647518e-06                    |
|  41   | Elapsed Time (Min:Sec)         | 0:25.11                           | 0:28.08                           | 0:29.32                           | 0:42.61                           | 0:40.62                           |
|  42   | Peak Memory Usage (MB)         | 165.31                            | 165.18                            | 165.18                            | 165.55                            | 165.14                            |
- WNS-Worst Negative Slack
- TNS-Total Negative Slack
- DFF-D Flip Flop
- FEP-Failing Endpoints
