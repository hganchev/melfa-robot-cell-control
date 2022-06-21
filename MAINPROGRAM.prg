1 'INPUTS
2 Def Io iSensorInGripper = Bit, 900    'N.O
3 Def Io iRunKey = Bit, 1               'N.O
4 Def Io iSensor1 = Bit, 12             'N.O at start of conveyor
5 Def Io iSensor2 = Bit, 11             'N.O at que gate
6 Def Io iSensor3 = Bit, 10             'N.C at robot end of conveyor
7 'OUTPUTS
8 Def Io oRemovePartConv = Bit, 11     'Remove part from conveyor
9 Def Io oConvAway = Bit, 10           'Conveyor away from robot
10 Def Io oConvToward = Bit, 9          'Conveyor towards Robot
11 Def Io oGate = Bit, 8                'Gate
12 'GRIPPER DATA
13 Def Pos GRP1                        'Casing Gripper
14 Def Pos GRP2                        'Spring and piston gripper
15 GRP1 = (+0.00,+0.00,+50.00,+0.00,+0.00,+0.00,+0.00,+0.00)(0,0)     ' -50 in Z direction
16 GRP2 = (-40.00,+0.00,+50.00,+0.00,+0.00,+0.00,+0.00,+0.00)(0,0)    ' 40 in X direction and -50 in Z direction
17 'Positions
18 Def Pos PEndOFConveyor              'Position Pick Casing on Sensor 3
19 Def Pos PAssemblyArea               'Position Assembly area For red casing
20 Def Pos PChute                      'Position Place on Chute
21 Def Pos PWatingConveyor             'Waiting Position
22 ' Pallets Definitions
23 Def Plt 1, PPlt1_1, PPlt1_2, PPlt1_3, PPlt1_4, 3, 3, 2 'Black Casing Pallet
24 Def Plt 2, PPlt2_1, PPlt2_2, PPlt2_3, PPlt2_4, 3, 3, 2 'Red casing Pallet
25 Def Plt 3, PPlt3_1, PPlt3_2, PPlt3_3, PPlt3_4, 4, 1, 3 'Piston pallet
26 Def Plt 4, PPlt4_1, PPlt4_2, PPlt4_3, PPlt4_4, 4, 1, 3 'spring pallet
27 Def Pos PPltPosBlack
28 Def Pos PPltPosRed
29 Def Pos PPltPosPiston
30 Def Pos PPltPosSpring
31 ' Robot Logic
32 Def Inte SimulatorActive
33 Def Inte RobotStep
34 Def Inte CycleFinished
35 RobotStep% = 0
36 SimulatorActive% = 1 ' Change If using Simulator - 1-Active, 0-Inactive
37 CycleFinished% = 0    ' Follows If cycle Is finished
38 *Start
39 If iRunKey = 1 Or SimulatorActive% = 1 Then
40     *Cycle
41     Select RobotStep%
42         Case 0 'Go to Waiting
43             CycleFinished% = 1
44             GoSub *RobotWaiting
45             RobotStep% = 1
46             Break
47         Case 1 'Waiting For piece on Conveyor
48             If iSensor3 Or SimulatorActive% Then
49                 CycleFinished% = 0
50                 RobotStep% = 2
51                 Break
52             EndIf
53             Break
54         Case 2 'Check casing color and pick the piece
55             GoSub *RobotCheckColor
56             RobotStep% = 3
57             Break
58         Case 3 'Decide about color
59             If bBlackCasing Then
60                 GoSub *RobotBlackCasing
61                 RobotStep% = 0
62             Else
63                 GoSub *RobotRedCasing
64                 RobotStep% = 4
65             EndIf
66             Break
67         Case 4 'Pick Piston and place it on the red Casing
68             GoSub *RobotPiston
69             RobotStep% = 5
70             Break
71         Case 5 'Pick Spring and place it on the red Casing
72             GoSub *RobotSpring
73             RobotStep% = 6
74             Break
75         Case 6 'Pick Assembled piece
76             GoSub *RobotPickAssembled
77             RobotStep% = 7
78             Break
79         Case 7 ' Place Assembled Piece on Chute
80             GoSub *RobotPlaceChute
81             RobotStep% = 0
82             Break
83         Default
84             Break
85     End Select
86     If CycleFinished% = 0 Then   'Check If Cycle Finished
87         GoTo *Cycle
88     EndIf
89 Else
90     Hlt
91     RobotStep% = 0
92 EndIf
93 GoTo *Start
94 '============== Sub Programs ========================
95 '================RobotWaiting========================
96 'Robot goes to Waiting position
97 '====================================================
98 *RobotWaiting
99 Tool 0
100 PCurrent = P_Curr
101 PCurrent.Z = 550   'Offset Z
102 Mov PCurrent        'Move to Z
103 Mov PWatingConveyor
104 Return
105 '================RobotCheckColor=====================
106 'Robot goes to position pick with Offset 1, Offset 2
107 'and Then pick the piece
108 '====================================================
109 *RobotCheckColor
110 Tool GRP1
111 Mov PEndOFConveyor * (+0.00,+0.00,-50.00,+0.00,+0.00,+0.00,+0.00,+0.00) 'Move Above the piece
112 Mvs PEndOFConveyor * (+0.00,+0.00,-5.00,+0.00,+0.00,+0.00,+0.00,+0.00)  'Check For Red Casing
113 If iSensorInGripper Then                                                'Sensor Detected
114     bBlackCasing = 0                                                    'Red Case detected
115 EndIf
116 Mvs PEndOFConveyor
117 If iSensorInGripper Then                                                'Sensor Detected
118    bBlackCasing = 1                                                     'Black Case detected
119 Else
120    If SimulatorActive% Then                                              'Change Color For Simulation
121         If bBlackCasing = 1 Then
122             bBlackCasing = 0
123         Else
124             bBlackCasing = 1
125         EndIf
126    Else
127         Hlt                                                                  ' Error no piece or piece not detected
128         RobotStep% = 0                                                       ' Return to Waiting Position
129    EndIf
130 EndIf
131 HClose 1
132 Dly 0.3                                                                 ' Gripper 1 Close
133 Mvs PEndOFConveyor * (+0.00,+0.00,-350.00,+0.00,+0.00,+0.00,+0.00,+0.00) 'Goes Up
134 Return
135 '================RobotBlackCasing====================
136 'Robot places the black casing on the pallet
137 '====================================================
138 *RobotBlackCasing
139 Tool GRP1
140 If N_TrayPosBlackCasing% = 0 Then                                           'Zero avoidance
141     N_TrayPosBlackCasing% = 1
142 ElseIf N_TrayPosBlackCasing% > 9 Then                                       'Check tray full
143     Hlt 'Full Black Casing Tray, Press Start to Continue
144     N_TrayPosBlackCasing% = 1                                               'After clearing tray pieces
145 EndIf
146 PPltPosBlack = Plt 1, N_TrayPosBlackCasing%                           'Get Pallet position
147 Mov PPltPosBlack * (+0.00,+0.00,-50.00,+0.00,+0.00,+0.00,+0.00,+0.00) 'Move to Pallet pos
148 Mvs PPltPosBlack                                                      'Linear Move to Pallet pos
149 HOpen 1                                                                     'Open Gripper 1
150 Dly 0.3                                                                     'Wait Open
151 Mvs PPltPosBlack * (+0.00,+0.00,-50.00,+0.00,+0.00,+0.00,+0.00,+0.00) 'Linear Move Up
152 N_TrayPosBlackCasing% = N_TrayPosBlackCasing% + 1                           'Increase tray Position
153 Return
154 '================RobotRedCasing====================
155 'Robot places the red casing on the assembly
156 '====================================================
157 *RobotRedCasing
158 Tool GRP1                                                                   'Tool 1
159 Mov PAssemblyArea * (+0.00,+0.00,-50.00,+0.00,+0.00,+0.00,+0.00,+0.00)      'Move to Assembly with Offset Z
160 Mvs PAssemblyArea                                                           'Linear Move to assembly
161 HOpen 1                                                                     'Open Gripper 1
162 Dly 0.3                                                                     'Wait Open
163 Mvs PAssemblyArea * (+0.00,+0.00,-50.00,+0.00,+0.00,+0.00,+0.00,+0.00)      'Move up
164 Return
165 '================RobotPiston=========================
166 'Robot picks the piston from pallet and place to red casing
167 '====================================================
168 *RobotPiston
169 Tool GRP2                                                                   'Tool 2
170 If N_TrayPosPiston% = 0 Then                                                'Check Zero
171     N_TrayPosPiston% = 1
172 ElseIf N_TrayPosPiston% > 4 Then                                            'Chck tray empty
173     Hlt ' Tray Piston Empty, Press Start to Continue
174     N_TrayPosPiston% = 1                                                    'Reset to 1-st pos
175 EndIf
176 PPltPosPiston = Plt 3, N_TrayPosPiston%                                     'Get Tray Posotion
177 Mov PPltPosPiston * (+0.00,+0.00,-50.00,+0.00,+0.00,+0.00,+0.00,+0.00)      'Move to tray pos with Offset Z
178 Mvs PPltPosPiston                                                           'Linear Move to Tray pos
179 HClose 2                                                                    'Close Gripper 2
180 Dly 0.3                                                                     'Wait Close
181 Mvs PPltPosPiston * (+0.00,+0.00,-50.00,+0.00,+0.00,+0.00,+0.00,+0.00)      'Move Up
182 N_TrayPosPiston% = N_TrayPosPiston% + 1                                     'Increase Tray pos
183 Mov PAssemblyArea * (+0.00,+0.00,-50.00,+0.00,+0.00,+0.00,+0.00,+0.00)      'MOve to Assembly with Offset Z
184 Mvs PAssemblyArea                                                           'Move to Assembly
185 HOpen 2                                                                     'Open Gripper 2
186 Dly 0.3                                                                     'Wait Open
187 Mvs PAssemblyArea * (+0.00,+0.00,-50.00,+0.00,+0.00,+0.00,+0.00,+0.00)      'move Up
188 Return
189 '================RobotSpring=========================
190 'Robot picks the spring from pallet and place to red casing
191 '====================================================
192 *RobotSpring
193 Tool GRP2                                                               'Tool 2
194 If N_TrayPosSpring% = 0 Then                                            'Check Zero
195     N_TrayPosSpring% = 1
196 ElseIf N_TrayPosSpring% > 4 Then                                        'Chck tray empty
197     Hlt ' Tray Spring Empty, Press Start to Continue
198     N_TrayPosSpring% = 1                                                'Reset to 1-st pos
199 EndIf
200 PPltPosSpring = Plt 4, N_TrayPosSpring%                                 'Get Tray Posotion
201 Mov PPltPosSpring * (+0.00,+0.00,-50.00,+0.00,+0.00,+0.00,+0.00,+0.00)  'Move to tray pos with Offset Z
202 Mvs PPltPosSpring                                                       'Linear Move to Tray pos
203 HClose 2                                                                'Close Gripper 2
204 Dly 0.3                                                                 'Wait Close
205 Mvs PPltPosSpring * (+0.00,+0.00,-50.00,+0.00,+0.00,+0.00,+0.00,+0.00)  'Move Up
206 N_TrayPosSpring% = N_TrayPosSpring% + 1                                 'Increase Tray pos
207 Mov PAssemblyArea * (+0.00,+0.00,-50.00,+0.00,+0.00,+0.00,+0.00,+0.00)  'MOve to Assembly with Offset Z
208 Mvs PAssemblyArea                                                       'Move to Assembly
209 HOpen 2                                                                 'Open Gripper 2
210 Dly 0.3                                                                 'Wait Open
211 Mvs PAssemblyArea * (+0.00,+0.00,-50.00,+0.00,+0.00,+0.00,+0.00,+0.00)  'move Up
212 Return
213 '================RobotPickAssembled====================
214 'Robot picks the assembled part
215 '====================================================
216 *RobotPickAssembled
217 Tool GRP1                                                               'Tool 1
218 Mov PAssemblyArea * (+0.00,+0.00,-50.00,+0.00,+0.00,+0.00,+0.00,+0.00)  'MOve to Assembly with Offset Z
219 Mvs PAssemblyArea                                                       'Move to Assembly
220 HClose 1                                                                'Close Gripper 1
221 Dly 0.3                                                                 'Wait Close
222 Mvs PAssemblyArea * (+0.00,+0.00,-50.00,+0.00,+0.00,+0.00,+0.00,+0.00)  'move Up
223 Return
224 '================RobotPlaceChute====================
225 'Robot places the assembled part to Chute
226 '====================================================
227 *RobotPlaceChute
228 Tool GRP1                                                           'Tool 1
229 Mov PChute * (+0.00,+0.00,-50.00,+0.00,+0.00,+0.00,+0.00,+0.00)     'MOve to Chute with Offset Z
230 Mvs PChute                                                          'Move to Chute
231 HOpen 1                                                             'Open Gripper 1
232 Dly 0.3                                                             'Wait Open
233 Mvs PChute * (+0.00,+0.00,-50.00,+0.00,+0.00,+0.00,+0.00,+0.00)     'move Up
234 Return
GRP1=(+0.00,+0.00,+50.00,+0.00,+0.00,+0.00,+0.00,+0.00)(0,0)
GRP2=(-40.00,+0.00,+50.00,+0.00,+0.00,+0.00,+0.00,+0.00)(0,0)
PEndOFConveyor=(+488.59,+173.37,+205.80,+180.00,+0.00,-180.00)(7,0)
PAssemblyArea=(-240.00,-545.00,+200.00,+180.00,+0.00,-180.00)(7,0)
PChute=(+250.58,+173.37,+205.72,+180.00,+0.00,-180.00)(7,0)
PWatingConveyor=(+409.99,+0.00,+655.14,+180.00,+0.00,-180.00)(7,0)
PPlt1_1=(+560.00,-80.00,+300.00,+180.00,+0.00,-180.00)(7,0)
PPlt1_2=(+560.00,+60.00,+300.00,+180.00,+0.00,-180.00)(7,0)
PPlt1_3=(+425.00,-80.00,+300.00,+180.00,+0.00,-180.00)(7,0)
PPlt1_4=(+425.00,+60.00,+300.00,+180.00,+0.00,-180.00)(7,0)
PPlt2_1=(+560.00,-320.00,+300.00,+180.00,+0.00,-180.00)(7,0)
PPlt2_2=(+560.00,-180.00,+300.00,+180.00,+0.00,-180.00)(7,0)
PPlt2_3=(+425.00,-320.00,+300.00,+180.00,+0.00,-180.00)(7,0)
PPlt2_4=(+425.00,-180.00,+300.00,+180.00,+0.00,-180.00)(7,0)
PPlt3_1=(-230.00,-410.00,+200.00,+180.00,+0.00,-180.00)(7,0)
PPlt3_2=(-230.00,-370.00,+200.00,+180.00,+0.00,-180.00)(7,0)
PPlt3_3=(-230.00,-330.00,+200.00,+180.00,+0.00,-180.00)(7,0)
PPlt3_4=(-230.00,-290.00,+200.00,+180.00,+0.00,-180.00)(7,0)
PPlt4_1=(-180.00,-410.00,+200.00,+180.00,+0.00,-180.00)(7,0)
PPlt4_2=(-180.00,-370.00,+200.00,+180.00,+0.00,-180.00)(7,0)
PPlt4_3=(-180.00,-330.00,+200.00,+180.00,+0.00,-180.00)(7,0)
PPlt4_4=(-180.00,-290.00,+200.00,+180.00,+0.00,-180.00)(7,0)
PPltPosBlack=(+560.00,-10.00,+300.00,+180.00,+0.00,-180.00)(7,0)
PPltPosRed=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PPltPosPiston=(-230.00,-383.33,+200.00,+180.00,+0.00,-180.00,+0.00,+0.00)(7,0)
PPltPosSpring=(-180.00,-410.00,+200.00,+180.00,+0.00,-180.00)(7,0)
PCurrent=(+560.00,-10.00,+550.00,-180.00,+0.00,+180.00,+0.00,+0.00)(7,0)
PPltSpring=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
