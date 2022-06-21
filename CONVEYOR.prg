1 'INPUTS
2 Def Io iSensorInGripper = Bit, 900    'N.O
3 Def Io iRunKey = Bit, 1               'N.O
4 Def Io iSensor1 = Bit, 12             'N.O at start of conveyor
5 Def Io iSensor2 = Bit, 11             'N.O at que gate
6 Def Io iSensor3 = Bit, 10             'N.C at robot end of conveyor
7 'OUTPUTS
8 Def Io oRemovePartConv = Bit, 11     'Remove part from conveyor
9 Def Io oConvAway = Bit, 10           'Conveyor away from robot - 1 = Run, 0 = Stop
10 Def Io oConvToward = Bit, 9          'Conveyor towards Robot - 1 = Run, 0 = Stop
11 Def Io oGate = Bit, 8                'Gate - 1 = Close, 0 = Open
12 Def Inte ConveyorStep
13 ConveyorStep% = 0
14 oConvAway = 0
15 oConvToward = 0
16 oGate = 1
17 *Start
18 If iRunKey = 1 Then
19     Select ConveyorStep%
20             Case 0
21                 oConvAway = 0   'Reset Conveyor Away
22                 oConvToward = 0 'Reset Conveyor Toward
23                 If Sensor3 = 1 Then
24                     'Wait For Unload part
25                 ElseIf Sensor2 = 1 Then
26                     ConveyorStep% = 1
27                 ElseIf Sensor1 = 1 Then
28                     ConveyorStep% = 4
29                 EndIf
30                 Break
31             Case 1 'Open Gate
32                 oGate = 0
33                 Dly 0.3
34                 ConveyorStep% = 2
35                 Break
36             Case 2 ' Run Toward
37                 oConvAway = 0
38                 oConvToward = 1
39                 If Sensor2 = 0 Then
40                     oGate = 1 ' Close gate
41                     Dly 0.3
42                     ConveyorStep% = 3
43                 EndIf
44                 Break
45             Case 3 'Wait Piece on Sensor3
46                 If Sensor3 Then
47                    Dly 0.3
48                    ConveyorStep% = 0
49                 EndIf
50                 Break
51             Case 4 ' Close Gate
52                 oGate = 1 ' Close gate
53                 ConveyorStep% = 5
54                 Break
55             Case 5 'Run Toward and Wait Sensor2
56                 oConvAway = 0
57                 oConvToward = 1
58                 If Sensor2 Then
59                     Dly 0.2
60                     ConveyorStep% = 0
61                 EndIf
62                 Break
63             Default
64                 Break
65     End Select
66 Else
67     ConveyorStep% = 0 'Reset Conveyor
68 EndIf
69 GoTo *Start
