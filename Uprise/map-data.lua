module(..., package.seeall)

function getAll(mapPack)
    local mapNumber = nil; local maps = {}

    if mapPack == 1 then

        -----------------------------------------------------------------
    
        mapNumber = 1
        maps[mapNumber] = {title = 'Convoy'}
    
        maps[mapNumber].towers = {
            {x = 326, y = 400, rotation = 90},
        }
    
        maps[mapNumber].dronePath = {
            {0, 223},
            {73, 223},
            {127, 275},
            {127, 465},
            {238, 467},
            {305, 401},
            {305, 303},
            {356, 250},
            {459, 250},
            {459, 724},
            {701, 726},
            {782, 646},
            {782, 499},
            {814, 467},
            {1211, 467},
        }
    
        maps[mapNumber].dronePathOther = {
            {0, 289},
            {164, 289},
            {209, 243},
            {517, 243},
            {646, 370},
            {1211, 370},
        }
    
        -----------------------------------------------------------------
    
        mapNumber = 2
        maps[mapNumber] = {title = 'Departed'}
    
        maps[mapNumber].towers = {
            {x = 240, y = 340, rotation = 0},
        }
    
        maps[mapNumber].dronePath = {
            {0, 380},
            {217, 380},
            {272, 326},
            {473, 326},
            {551, 247},
            {765, 247},
            {839, 175},
            {1212, 175},
        }
    
        maps[mapNumber].dronePathOther = {
            {0, 389},
            {217, 389},
            {272, 451},
            {473, 451},
            {551, 529},
            {765, 529},
            {846, 604},
            {1212, 604},
        }
    
        -----------------------------------------------------------------
    
        mapNumber = 3
        maps[mapNumber] = {title = 'Convergence'}
    
        maps[mapNumber].towers = {
            {x = 721, y = 258, rotation = -90},
        }
    
        maps[mapNumber].dronePath = {
            {0, 239},
            {67, 239},
            {210, 96},
            {294, 97},
            {886, 691},
            {1109, 470},
            {1109, 172},
            {1212, 172},
        }
    
        maps[mapNumber].dronePathOther = {
            {0, 648},
            {119, 648},
            {748, 364},
            {884, 364},
            {938, 155},
            {1212, 155},
        }
    
        -----------------------------------------------------------------
    
        mapNumber = 4
        maps[mapNumber] = {title = 'Circle'}
    
        maps[mapNumber].towers = {
            {x = 311, y = 454, rotation = 180},
        }
    
        maps[mapNumber].dronePath = {
            {0, 159},
            {608, 159},
            {775, 195},
            {871, 318},
            {871, 470},
            {781, 611},
            {506, 611},
            {426, 503},
            {529, 387},
            {1212, 387},
        }
    
        maps[mapNumber].dronePathOther = {
            {0, 238},
            {654, 237},
            {830, 374},
            {1212, 374},
        }
    
        -----------------------------------------------------------------
    
        mapNumber = 5
        maps[mapNumber] = {title = 'Frequency'}
    
        maps[mapNumber].towers = {
            {x = 799, y = 425, rotation = 0},
        }
    
        maps[mapNumber].dronePath = {
            {0, 163},
            {133, 163},
            {333, 582},
            {445, 582},
            {551, 370},
            {668, 370},
            {914, 676},
            {1212, 676},
        }
    
        maps[mapNumber].dronePathOther = {
            {0, 601},
            {133, 601},
            {333, 178},
            {445, 178},
            {551, 392},
            {668, 392},
            {914, 85},
            {1212, 85},
        }
    
        -----------------------------------------------------------------
    
        mapNumber = 6
        maps[mapNumber] = {title = 'Crossroads'}
    
        maps[mapNumber].towers = {
            {x = 261, y = 227, rotation = -90},
        }
    
        maps[mapNumber].dronePath = {
            {0, 94},
            {102, 94},
            {188, 180},
            {188, 424},
            {110, 501},
            {110, 589},
            {156, 637},
            {393, 637},
            {801, 230},
            {804, 115},
            {1212, 115},
        }
    
        maps[mapNumber].dronePathOther = {
            {0, 333},
            {337, 333},
            {625, 116},
            {965, 456},
            {1212, 456},
        }
    
        -----------------------------------------------------------------
    
        mapNumber = 7
        maps[mapNumber] = {title = 'Triangle'}
    
        maps[mapNumber].towers = {
            {x = 695, y = 451, rotation = 0},
        }
    
        maps[mapNumber].dronePath = {
            {0, 232},
            {114, 134},
            {389, 410},
            {938, 408},
            {668, 138},
            {668, 768},
        }
    
        maps[mapNumber].dronePathOther = {
            {0, 476},
            {440, 476},
            {559, 591},
            {1212, 591},
        }
    
        -----------------------------------------------------------------
    
        mapNumber = 8
        maps[mapNumber] = {title = 'Return'}
    
        maps[mapNumber].towers = {
            {x = 494, y = 480, rotation = 180},
        }
    
        maps[mapNumber].dronePath = {
            {0, 190},
            {829, 190},
            {945, 238},
            {1034, 373},
            {956, 557},
            {830, 613},
            {0, 613},
        }
    
        maps[mapNumber].dronePathOther = {
            {0, 212},
            {270, 212},
            {497, 373},
            {1212, 373},
        }
    
        -----------------------------------------------------------------
    
        mapNumber = 9
        maps[mapNumber] = {title = 'Lightning'}
    
        maps[mapNumber].towers = {
            {x = 383, y = 404, rotation = 90},
        }
    
        maps[mapNumber].dronePath = {
            {0, 133},
            {254, 191},
            {488, 148},
            {619, 424},
            {687, 388},
            {734, 613},
            {987, 408},
            {529, 144},
            {1212, 117},
        }
    
        maps[mapNumber].dronePathOther = {
            {0, 214},
            {275, 423},
            {467, 375},
            {575, 602},
            {631, 563},
            {720, 654},
            {1025, 399},
            {1212, 340},
        }
    
        -----------------------------------------------------------------
    
        mapNumber = 10
        maps[mapNumber] = {title = 'Perpendicular'}
    
        maps[mapNumber].towers = {
            {x = 817, y = 452, rotation = 0},
        }
    
        maps[mapNumber].dronePath = {
            {0, 132},
            {353, 132},
            {353, 476},
            {435, 476},
            {435, 533},
            {579, 533},
            {583, 245},
            {709, 244},
            {709, 319},
            {1212, 319},
        }
    
        maps[mapNumber].dronePathOther = {
            {0, 568},
            {198, 568},
            {198, 231},
            {438, 231},
            {438, 357},
            {568, 358},
            {568, 445},
            {866, 445},
            {866, 128},
        }
    
        -----------------------------------------------------------------
    
        mapNumber = 11
        maps[mapNumber] = {title = 'Contrasts'}
    
        maps[mapNumber].towers = {
            {x = 754, y = 241, rotation = 0},
        }
    
        maps[mapNumber].dronePath = {
            {0, 128},
            {83, 128},
            {299, 230},
            {389, 384},
            {297, 521},
            {297, 601},
            {906, 601},
            {906, 521},
            {546, 390},
            {621, 240},
            {1212, 170},
        }
    
        maps[mapNumber].dronePathOther = {
            {0, 602},
            {680, 563},
            {769, 0},
        }
    
        -----------------------------------------------------------------
    
        mapNumber = 12
        maps[mapNumber] = {title = 'Splitter'}
    
        maps[mapNumber].towers = {
            {x = 547, y = 446, rotation = 45},
        }
    
        maps[mapNumber].dronePath = {
            {0, 133},
            {724, 133},
            {948, 207},
            {1041, 323},
            {1041, 441},
            {483, 440},
            {254, 766},
        }
    
        maps[mapNumber].dronePathOther = {
            {0, 215},
            {716, 215},
            {913, 294},
            {913, 428},
            {776, 428},
            {350, 0},
        }
    
        -----------------------------------------------------------------
    
        mapNumber = 13
        maps[mapNumber] = {title = 'Central'}
    
        maps[mapNumber].towers = {
            {x = 560, y = 391, rotation = 0},
        }
    
        maps[mapNumber].dronePath = {
            {112, 0},
            {112, 130},
            {244, 260},
            {1212, 260},
        }
    
        maps[mapNumber].dronePathOther = {
            {839, 766},
            {650, 577},
            {343, 577},
            {241, 476},
            {241, 170},
            {756, 170},
            {933, 346},
            {1212, 346},
        }
    
        -----------------------------------------------------------------
    
        mapNumber = 14
        maps[mapNumber] = {title = 'Warp'}
    
        maps[mapNumber].towers = {
            {x = 282, y = 387, rotation = 215},
        }
    
        maps[mapNumber].dronePath = {
            {0, 507},
            {759, 508},
            {864, 401},
            {764, 301},
            {294, 767},
        }
    
        maps[mapNumber].dronePathOther = {
            {579, 766},
            {579, 0},
        }
    
        -----------------------------------------------------------------
    
        mapNumber = 15
        maps[mapNumber] = {title = 'Zagged'}
    
        maps[mapNumber].towers = {
            {x = 321, y = 264, rotation = 315},
        }
    
        maps[mapNumber].dronePath = {
            {0, 122},
            {429, 450},
            {640, 282},
            {906, 644},
            {1212, 577},
        }
    
        maps[mapNumber].dronePathOther = {
            {0, 248},
            {258, 656},
            {211, 316},
            {604, 653},
            {878, 170},
            {997, 473},
            {1212, 390},
        }
    
        -----------------------------------------------------------------
    
        mapNumber = 16
        maps[mapNumber] = {title = 'Embedded'}
    
        maps[mapNumber].towers = {
            {x = 637, y = 401, rotation = 45},
        }
    
        maps[mapNumber].dronePath = {
            {0, 215},
            {590, 214},
            {1147, 768},
        }
    
        maps[mapNumber].dronePathOther = {
            {0, 631},
            {574, 630},
            {651, 555},
            {574, 479},
            {323, 479},
            {262, 415},
            {327, 350},
            {1212, 350},
        }
    
        -----------------------------------------------------------------
    
        mapNumber = 17
        maps[mapNumber] = {title = 'Destination'}
    
        maps[mapNumber].towers = {
            {x = 796, y = 166, rotation = 0},
        }
    
        maps[mapNumber].dronePath = {
            {0, 365},
            {399, 365},
            {471, 295},
            {445, 254},
            {334, 205},
            {347, 134},
            {593, 122},
            {716, 338},
            {772, 327},
            {796, 0},
        }
    
        maps[mapNumber].dronePathOther = {
            {0, 390},
            {400, 390},
            {422, 408},
            {404, 537},
            {335, 569},
            {317, 625},
            {381, 681},
            {532, 616},
            {565, 546},
            {750, 551},
            {794, 630},
            {932, 655},
            {956, 450},
            {1055, 416},
            {1122, 545},
            {1212, 564},
        }
    
        -----------------------------------------------------------------
    
        mapNumber = 18
        maps[mapNumber] = {title = 'Proximity'}
    
        maps[mapNumber].towers = {
            {x = 369, y = 266, rotation = 180},
        }
    
        maps[mapNumber].dronePath = {
            {140, 0},
            {122, 135},
            {203, 212},
            {362, 151},
            {506, 218},
            {524, 354},
            {623, 381},
            {695, 278},
            {880, 299},
            {990, 169},
            {912, 128},
            {992, 0},
        }
    
        maps[mapNumber].dronePathOther = {
            {0, 582},
            {158, 625},
            {247, 500},
            {394, 450},
            {507, 498},
            {597, 473},
            {686, 581},
            {678, 653},
            {819, 710},
            {888, 474},
            {1099, 426},
            {1140, 0},
        }
    
        -----------------------------------------------------------------
    
        mapNumber = 19
        maps[mapNumber] = {title = 'Parallels'}
    
        maps[mapNumber].towers = {
            {x = 562, y = 136, rotation = 0},
        }
    
        maps[mapNumber].dronePath = {
            {0, 343},
            {116, 234},
            {243, 235},
            {288, 278},
            {1212, 278},
        }
    
        maps[mapNumber].dronePathOther = {
            {0, 491},
            {123, 372},
            {240, 373},
            {275, 518},
            {460, 616},
            {522, 576},
            {420, 465},
            {443, 391},
            {720, 595},
            {871, 583},
            {758, 425},
            {1212, 373},
        }
    
        -----------------------------------------------------------------
    
        mapNumber = 20
        maps[mapNumber] = {title = 'Turmoil'}
    
        maps[mapNumber].towers = {
            {x = 369, y = 225, rotation = 215},
        }
    
        maps[mapNumber].dronePath = {
            {0, 263},
            {229, 384},
            {366, 384},
            {639, 537},
            {797, 537},
            {898, 478},
            {816, 415},
            {633, 415},
            {474, 574},
            {591, 641},
            {880, 641},
            {1082, 528},
            {381, 0},
        }
    
        maps[mapNumber].dronePathOther = {
            {316, 767},
            {613, 470},
            {613, 304},
            {498, 305},
            {351, 449},
            {928, 767},
        }
    
        -----------------------------------------------------------------
    
        mapNumber = 21
        maps[mapNumber] = {title = 'Twin'}
    
        maps[mapNumber].towers = {
            {x = 684, y = 341, rotation = 180},
        }
    
        maps[mapNumber].dronePath = {
            {96, 0},
            {155, 185},
            {334, 283},
            {813, 282},
            {994, 180},
            {1061, 0},
        }
    
        maps[mapNumber].dronePathOther = {
            {93, 768},
            {191, 585},
            {417, 488},
            {778, 495},
            {1101, 309},
            {1212, 312},
        }
    
        -----------------------------------------------------------------
    
        mapNumber = 22
        maps[mapNumber] = {title = 'Juxtapose'}
    
        maps[mapNumber].towers = {
            {x = 452, y = 314, rotation = 180},
        }
    
        maps[mapNumber].dronePath = {
            {0, 157},
            {159, 157},
            {287, 285},
            {461, 114},
            {613, 266},
            {709, 170},
            {1212, 170},
        }
    
        maps[mapNumber].dronePathOther = {
            {0, 536},
            {696, 536},
            {696, 414},
            {782, 414},
            {782, 601},
            {1212, 601},
        }
    
        -----------------------------------------------------------------
    
        mapNumber = 23
        maps[mapNumber] = {title = 'Reroute'}
    
        maps[mapNumber].towers = {
            {x = 915, y = 244, rotation = 215},
        }
    
        maps[mapNumber].dronePath = {
            {106, 0},
            {106, 311},
            {306, 311},
            {507, 110},
            {831, 434},
            {1212, 434},
        }
    
        maps[mapNumber].dronePathOther = {
            {0, 490},
            {317, 490},
            {416, 390},
            {558, 390},
            {558, 594},
            {751, 595},
            {695, 538},
            {0, 613},
        }
    
        -----------------------------------------------------------------
    
        mapNumber = 24
        maps[mapNumber] = {title = 'Secede'}
    
        maps[mapNumber].towers = {
            {x = 785, y = 360, rotation = 0},
        }
    
        maps[mapNumber].dronePath = {
            {0, 476},
            {203, 478},
            {334, 416},
            {177, 284},
            {297, 125},
            {636, 181},
            {828, 341},
            {1035, 269},
            {1085, 0},
        }
    
        maps[mapNumber].dronePathOther = {
            {0, 589},
            {262, 696},
            {455, 577},
            {543, 664},
            {650, 566},
            {560, 386},
            {894, 502},
            {878, 659},
            {1103, 767},
        }
    
        -----------------------------------------------------------------
    
        mapNumber = 25
        maps[mapNumber] = {title = 'Simplicity'}
    
        maps[mapNumber].towers = {
            {x = 371, y = 340, rotation = 0},
        }
    
        maps[mapNumber].dronePath = {
            {0, 289},
            {1212, 289},
        }
    
        maps[mapNumber].dronePathOther = {
            {0, 491},
            {1212, 491},
        }
    
        -----------------------------------------------------------------
    
        mapNumber = 26
        maps[mapNumber] = {title = 'Symmetry'}
    
        maps[mapNumber].towers = {
            {x = 574, y = 337, rotation = 180},
        }
    
        maps[mapNumber].dronePath = {
            {0, 156},
            {307, 156},
            {929, 308},
            {622, 0},
        }
    
        maps[mapNumber].dronePathOther = {
            {0, 611},
            {307, 611},
            {929, 460},
            {622, 768},
        }
    
        -----------------------------------------------------------------
    
        mapNumber = 27
        maps[mapNumber] = {title = 'Curve'}
    
        maps[mapNumber].towers = {
            {x = 699, y = 394, rotation = 180},
        }
    
        maps[mapNumber].dronePath = {
            {0, 120},
            {607, 120},
            {897, 236},
            {971, 416},
            {862, 599},
            {421, 600},
            {287, 763},
        }
    
        -----------------------------------------------------------------
    
        mapNumber = 28
        maps[mapNumber] = {title = 'Spiked'}
    
        maps[mapNumber].towers = {
            {x = 770, y = 306, rotation = 315},
        }
    
        maps[mapNumber].dronePath = {
            {178, 0},
            {178, 142},
            {302, 336},
            {686, 337},
            {659, 371},
            {469, 371},
            {317, 523},
            {886, 525},
            {1129, 767},
        }
    
        -----------------------------------------------------------------
    
        mapNumber = 29
        maps[mapNumber] = {title = 'Turns'}
    
        maps[mapNumber].towers = {
            {x = 204, y = 367, rotation = 90},
        }
    
        maps[mapNumber].dronePath = {
            {211, 0},
            {211, 234},
            {359, 234},
            {359, 164},
            {531, 164},
            {531, 336},
            {340, 336},
            {339, 477},
            {841, 477},
            {842, 338},
            {969, 339},
            {969, 607},
            {862, 607},
            {862, 688},
            {1212, 688},
        }
    
        -----------------------------------------------------------------
    
        mapNumber = 30
        maps[mapNumber] = {title = 'Twist'}
    
        maps[mapNumber].towers = {
            {x = 751, y = 242, rotation = 45},
        }
    
        maps[mapNumber].dronePath = {
            {0, 222},
            {140, 222},
            {259, 170},
            {683, 320},
            {811, 517},
            {581, 612},
            {516, 348},
            {738, 179},
            {903, 169},
            {1212, 469},
        }
    
        -----------------------------------------------------------------
    
        mapNumber = 31
        maps[mapNumber] = {title = 'Grip'}
    
        maps[mapNumber].towers = {
            {x = 626, y = 271, rotation = 45},
        }
    
        maps[mapNumber].dronePath = {
            {0, 204},
            {171, 501},
            {475, 697},
            {793, 693},
            {763, 582},
            {486, 449},
            {325, 257},
            {437, 166},
            {886, 257},
            {1044, 409},
            {1162, 355},
            {1079, 135},
            {886, 0},
        }
    
        -----------------------------------------------------------------
    
        mapNumber = 32
        maps[mapNumber] = {title = 'Surround'}
    
        maps[mapNumber].towers = {
            {x = 771, y = 310, rotation = 315},
        }
    
        maps[mapNumber].dronePath = {
            {0, 541},
            {84, 541},
            {173, 633},
            {345, 534},
            {260, 275},
            {449, 86},
            {701, 162},
            {758, 268},
            {615, 470},
            {935, 565},
            {1092, 407},
            {1210, 467},
        }
    
        -----------------------------------------------------------------
    
        mapNumber = 33
        maps[mapNumber] = {title = 'Separated'}
    
        maps[mapNumber].towers = {
            {x = 563, y = 324, rotation = 0},
        }
    
        maps[mapNumber].dronePath = {
            {0, 371},
            {391, 371},
            {559, 203},
            {673, 204},
            {730, 262},
            {1003, 0},
        }
    
        maps[mapNumber].dronePathOther = {
            {0, 371},
            {391, 371},
            {559, 538},
            {673, 538},
            {730, 476},
            {1003, 768},
        }
    
        -----------------------------------------------------------------
    
        mapNumber = 34
        maps[mapNumber] = {title = 'Net'}
    
        maps[mapNumber].towers = {
            {x = 860, y = 224, rotation = 315},
        }
    
        maps[mapNumber].dronePath = {
            {74, 0},
            {154, 209},
            {366, 235},
            {542, 177},
            {763, 191},
            {954, 418},
            {1212, 486},
        }
    
        maps[mapNumber].dronePathOther = {
            {74, 0},
            {154, 209},
            {366, 235},
            {201, 430},
            {371, 620},
            {750, 538},
            {954, 418},
            {1212, 486},
        }
    
        -----------------------------------------------------------------
    
        mapNumber = 35
        maps[mapNumber] = {title = 'Loop'}
    
        maps[mapNumber].towers = {
            {x = 702, y = 224, rotation = 0},
        }
    
        maps[mapNumber].dronePath = {
            {0, 165},
            {254, 165},
            {485, 215},
    
            {671, 343},
            {624, 518},
            {442, 533},
            {424, 393},
    
            {671, 343},
            {624, 518},
            {442, 533},
            {424, 393},
    
            {671, 343},
    
            {861, 505},
            {1007, 768},
        }
    
        -----------------------------------------------------------------
    
        mapNumber = 36
        maps[mapNumber] = {title = 'Reverse'}
    
        maps[mapNumber].towers = {
            {x = 446, y = 262, rotation = 315},
        }
    
        maps[mapNumber].dronePath = {
            {0, 149},
            {160, 176},
            {300, 301},
            {493, 547},
            {750, 606},
            {893, 494},
            {862, 333},
            {681, 285},
            {611, 351},
            {685, 455},
            {752, 466},
    
            {685, 455},
            {611, 351},
            {681, 285},
            {862, 333},
            {893, 494},
            {750, 606},
            {493, 547},
            {300, 301},
            {160, 176},
            {0, 149},
        }
    
        -----------------------------------------------------------------
    
        mapNumber = 37
        maps[mapNumber] = {title = 'Synchronized'}
    
        maps[mapNumber].towers = {
            {x = 337, y = 282, rotation = 225},
        }
    
        maps[mapNumber].dronePath = {
            {0, 502},
            {204, 369},
            {284, 422},
            {420, 428},
            {563, 287},
            {653, 323},
            {789, 314},
            {977, 89},
            {1090, 139},
            {1212, 140},
        }
    
        maps[mapNumber].dronePathOther = {
            {0, 502 + 173},
            {204, 369 + 173},
            {284, 422 + 173},
            {420, 428 + 173},
            {563, 287 + 173},
            {653, 323 + 173},
            {789, 314 + 173},
            {977, 89 + 173},
            {1090, 139 + 173},
            {1212, 140 + 173},
        }
    
        -----------------------------------------------------------------

        mapNumber = 38
        maps[mapNumber] = {title = 'Direct'}
    
        maps[mapNumber].towers = {
            {x = 558, y = 275, rotation = 270},
        }
    
        maps[mapNumber].dronePath = {
            {0, 385},
            {1212, 385},
        }
    
        -----------------------------------------------------------------

        mapNumber = 39
        maps[mapNumber] = {title = 'Edge'}
    
        maps[mapNumber].towers = {
            {x = 357, y = 376, rotation = 315},
        }
    
        maps[mapNumber].dronePath = {
            {305, 0},
            {305, 522},
            {1212, 522},
        }

        -----------------------------------------------------------------

        mapNumber = 40
        maps[mapNumber] = {title = 'Detour'}
    
        maps[mapNumber].towers = {
            {x = 546, y = 336, rotation = 180},
        }
    
        maps[mapNumber].dronePath = {
            {573, 0},
            {954, 381},
            {568, 768},
        }
    
        -----------------------------------------------------------------

    elseif mapPack == 2 then

        mapNumber = 1
        maps[mapNumber] = {title = 'Barrier'}
    
        maps[mapNumber].towers = {
            {x = 747, y = 337, rotation = 0},
        }

        maps[mapNumber].dronePath = {
            {0, 382},
            {205, 382},
            {287, 258},
            {375, 258},
            {472, 602},
            {529, 602},
            {529, 177},
            {834, 177},
            {918, 259},
        }
    
        maps[mapNumber].obstacles = {
            {593,246, 0},
        }
    
        -----------------------------------------------------------------

        mapNumber = 2
        maps[mapNumber] = {title = 'Guarded'}
    
        maps[mapNumber].towers = {
            {x = 247, y = 413, rotation = 135},
        }
    
        maps[mapNumber].dronePath = {
            {0, 164},
            {385, 164},
            {606, 386},
            {606, 611},
            {916, 611},
            {1212, 318},
        }

        maps[mapNumber].obstacles = {
            {259 + 79,293 - 20, -45},
            {735 + 79,293 - 20, 45},
        }

        -----------------------------------------------------------------

        mapNumber = 3
        maps[mapNumber] = {title = 'X'}
    
        maps[mapNumber].towers = {
            {x = 407, y = 121, rotation = 0},
        }
    
        maps[mapNumber].dronePath = {
            {181, 0},
            {181, 316},
            {448, 316},
            {603, 470},
            {1022, 470},
            {1022, 639},
            {1212, 639},
        }
    
        maps[mapNumber].obstacles = {
            {310,-11, 0},
            {900,530, 0},
        }
    
        -----------------------------------------------------------------

        mapNumber = 4
        maps[mapNumber] = {title = 'Blocked'}
    
        maps[mapNumber].towers = {
            {x = 866, y = 326, rotation = 0},
        }
    
        maps[mapNumber].dronePath = {
            {0, 377},
            {220, 377},
            {342, 177},
            {530, 121},
            {774, 235},
            {765, 479},
            {566, 568},
            {502, 459},
            {631, 361},
            {882, 446},
            {1096, 590},
            {1212, 590},
        }
    
        maps[mapNumber].obstacles = {
            {417,333, 0},
            {811,333, 0},
        }
    
        -----------------------------------------------------------------

        mapNumber = 5
        maps[mapNumber] = {title = 'Bordering'}
    
        maps[mapNumber].towers = {
            {x = 884, y = 340, rotation = 0},
        }
    
        maps[mapNumber].dronePath = {
            {31, 153},
            {637, 153},
            {778, 261},
            {687, 386},
            {778, 511},
            {637, 619},
            {0, 619},
        }
    
        maps[mapNumber].obstacles = {
            {833,263, 0},
        }
    
        -----------------------------------------------------------------

        mapNumber = 6
        maps[mapNumber] = {title = 'Diversion'}
    
        maps[mapNumber].towers = {
            {x = 801, y = 432, rotation = 45},
        }
    
        maps[mapNumber].dronePath = {
            {172, 768},
            {340, 584},
            {204, 355},
            {405, 153},
            {541, 170},
            {489, 415},
            {733, 402},
            {1136, 0},
        }

        maps[mapNumber].obstacles = {
            {268 + 79,185 - 20, 45},
            {693 + 79,335 - 20, 45},
        }
    
        -----------------------------------------------------------------

        mapNumber = 7
        maps[mapNumber] = {title = 'Walls'}
    
        maps[mapNumber].towers = {
            {x = 678, y = 197, rotation = 0},
        }
    
        maps[mapNumber].dronePath = {
            {119, 0},
            {168, 116},
            {369, 282},
            {712, 346},
            {1212, 346},
        }
    
        maps[mapNumber].dronePathOther = {
            {0, 658},
            {350, 659},
            {623, 552},
            {713, 441},
            {1212, 441},
        }

        maps[mapNumber].obstacles = {
            {716 + 100,367 - 100, 90},
            {972 + 100,367 - 100, 90},
        }
    
        -----------------------------------------------------------------

        mapNumber = 8
        maps[mapNumber] = {title = 'Arrangement'}
    
        maps[mapNumber].towers = {
            {x = 759, y = 466, rotation = 0},
        }
    
        maps[mapNumber].dronePath = {
            {0, 371},
            {269, 373},
            {431, 306},
            {431, 140},
            {756, 140},
            {756, 332},
            {993, 332},
            {993, 0},
        }
    
        maps[mapNumber].dronePathOther = {
            {0, 371},
            {269, 373},
            {488, 594},
            {738, 594},
            {738, 453},
            {1212, 453},
        }

        maps[mapNumber].obstacles = {
            {188,73, 0},
            {742 + 100,366 - 100, 90},
            {469 + 56, 309 - 8, -30},
        }
    
        -----------------------------------------------------------------

    elseif mapPack == 3 then

        mapNumber = 1
        maps[mapNumber] = {title = 'Power'}
    
        maps[mapNumber].towers = {
            {x = 417, y = 225, rotation = 270},
            {x = 564, y = 531, rotation = 0},
        }

        maps[mapNumber].dronePath = {
            {0, 382},
            {205, 382},
            {287, 258},
            {375, 258},
            {472, 602},
            {529, 602},
            {529, 177},
            {834, 177},
            {918, 259},
            {1212, 259},
        }

        -----------------------------------------------------------------

        mapNumber = 2
        maps[mapNumber] = {title = 'United'}
    
        maps[mapNumber].towers = {
            {x = 545, y = 425, rotation = 270},
            {x = 770, y = 425, rotation = 270},
        }
    
        maps[mapNumber].dronePath = {
            {0, 260},
            {198, 260},
            {321, 187},
            {397, 189},
            {397, 474},
            {561, 577},
            {896, 577},
            {896, 389},
            {1212, 75},
        }
    
        -----------------------------------------------------------------

        mapNumber = 3
        maps[mapNumber] = {title = 'Opposing'}
    
        maps[mapNumber].towers = {
            {x = 318, y = 267, rotation = 315},
            {x = 469, y = 396, rotation = 135},
        }
    
        maps[mapNumber].dronePath = {
            {163, 0},
            {163, 239},
            {375, 451},
            {634, 195},
            {895, 457},
            {624, 458},
            {624, 768},
        }
   
        -----------------------------------------------------------------

        mapNumber = 4
        maps[mapNumber] = {title = 'Protected'}
    
        maps[mapNumber].towers = {
            {x = 386, y = 540, rotation = 180},
            {x = 801, y = 540, rotation = 0},
        }
    
        maps[mapNumber].dronePath = {
            {0, 372},
            {151, 372},
            {189, 416},
            {251, 254},
            {298, 312},
            {454, 279},
            {528, 609},
            {765, 609},
            {663, 99},
            {589, 97},
            {565, 300},
            {1212, 468},
        }
       
        -----------------------------------------------------------------

        mapNumber = 5
        maps[mapNumber] = {title = 'Overturn'}
    
        maps[mapNumber].towers = {
            {x = 484, y = 571, rotation = 180},
            {x = 582, y = 571, rotation = 0},
        }
    
        maps[mapNumber].dronePath = {
            {166, 0},
            {166, 225},
            {491, 225},
            {491, 353},
            {310, 353},
            {310, 567},
            {1005, 567},
            {1005, 370},
            {885, 370},
            {885, 274},
            {1081, 274},
            {1081, 0},
        }
       
        -----------------------------------------------------------------

        mapNumber = 6
        maps[mapNumber] = {title = 'Double'}
    
        maps[mapNumber].towers = {
            {x = 676, y = 427, rotation = 0},
            {x = 676, y = 494, rotation = 0},
        }
    
        maps[mapNumber].dronePath = {
            {202, 768},
            {202, 565},
            {400, 565},
            {620, 356},
            {419, 356},
            {360, 285},
            {496, 284},
            {496, 184},
            {914, 184},
            {711, 389},
            {1212, 389},
        }
    
        -----------------------------------------------------------------

        mapNumber = 7
        maps[mapNumber] = {title = 'Forward'}
    
        maps[mapNumber].towers = {
            {x = 563, y = 254, rotation = 270},
            {x = 563, y = 429, rotation = 90},
        }
    
        maps[mapNumber].dronePath = {
            {0, 384},
            {1212, 384},
        }
    
        -----------------------------------------------------------------

        mapNumber = 8
        maps[mapNumber] = {title = 'Mirror'}
    
        maps[mapNumber].towers = {
            {x = 230, y = 437, rotation = 0},
            {x = 906, y = 437, rotation = 180},
        }
    
        maps[mapNumber].dronePath = {
            {0, 143},
            {133, 143},
            {203, 210},
            {170, 285},
            {287, 369},
            {553, 205},
            {694, 379},
            {911, 404},
            {1022, 337},
            {1086, 373},
            {1136, 319},
            {1053, 281},
            {1212, 123},
        }
    
        -----------------------------------------------------------------

    end

        --[[
    
        mapNumber = N
        maps[mapNumber] = {title = ''}
    
        maps[mapNumber].towers = {
            {x = , y = , rotation = 0},
        }
    
        maps[mapNumber].dronePath = {
            {, },
        }
    
        maps[mapNumber].dronePathOther = {
            {, },
        }
    
        -----------------------------------------------------------------
    
        --]]

    return maps
end

function getStartXY()
    local startXY = app.mapData[app.mapNumber].enemyPath[1]
    return startXY[2], startXY[3]
end

function getCoordinatesFromShape(shape)
    local centerX = nil; local centerY = nil; local width = nil; local height = nil; local polygonShape = nil

    if shape.x ~= nil and shape.width ~= nil then
        centerX, centerY = shape.x, shape.y
        width, height = shape.width, shape.height

    elseif shape.x1 ~= nil and shape.width ~= nil then
        centerX, centerY = shape.x1 + shape.width / 2, shape.y1 + shape.height / 2
        width, height = shape.width, shape.height

    elseif shape.x1 ~= nil then
        width, height = shape.x2 - shape.x1, shape.y2 - shape.y1
        centerX, centerY = shape.x1 + width / 2, shape.y1 + height / 2

    else
        polygonShape = shape
        x, y = getShapeLowestXY(polygonShape)
        width, height = getShapeWidthHeight(polygonShape)
        centerX, centerY = x + width / 2, y + height / 2
        polygonShape = getRelativeShape(polygonShape)

    end

    return centerX, centerY, width, height, polygonShape
end

function getRelativeShape(shape)
    local minX, minY = getShapeLowestXY(shape)
    for i = 1, #shape, 2 do
        local iX = i; local iY = i + 1
        shape[iX] = shape[iX] - minX
        shape[iY] = shape[iY] - minY
    end
    return shape
end

function getShapeLowestXY(shape)
    local lowestX = nil; local lowestY = nil
    for i = 1, #shape, 2 do
        local x = shape[i]; local y = shape[i + 1]
        if lowestX == nil or x < lowestX then lowestX = x end
        if lowestY == nil or y < lowestY then lowestY = y end
    end
    return lowestX, lowestY
end

function getShapeHighestXY(shape)
    local highestX = nil; local highestY = nil
    for i = 1, #shape, 2 do
        local x = shape[i]; local y = shape[i + 1]
        if highestX == nil or x > highestX then highestX = x end
        if highestY == nil or y > highestY then highestY = y end
    end
    return highestX, highestY
end

function getShapeWidthHeight(shape)
    local minX, minY = getShapeLowestXY(shape)
    local maxX, maxY = getShapeHighestXY(shape)
    local width = math.abs(maxX - minX)
    local height = math.abs(maxY - minY)
    return width, height
end
