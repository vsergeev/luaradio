-- Do not edit! This file was generated by blocks/signal/fmpreemphasisfilter_spec.py

local radio = require('radio')
local jigs = require('tests.jigs')

jigs.TestBlock(radio.FMPreemphasisFilterBlock, {
    {
        desc = "5e-6 tau, 256 Float32 input, 256 Float32 output",
        args = {5e-06},
        inputs = {radio.types.Float32.vector_from_array({-0.73127151, 0.69486749, 0.52754927, -0.48986191, -0.00912983, -0.10101787, 0.30318594, 0.57744670, -0.81228077, -0.94330502, 0.67153019, -0.13446586, 0.52456015, -0.99578792, -0.10922561, 0.44308007, -0.54247558, 0.89054137, 0.80285490, -0.93882000, -0.94910830, 0.08282494, 0.87829834, -0.23759152, -0.56680119, -0.15576684, -0.94191837, -0.55661666, -0.12422481, -0.00837552, -0.53383112, -0.53826690, -0.56243795, -0.08079307, -0.42043677, -0.95702058, 0.67515594, 0.11290865, 0.28458872, -0.62818748, 0.98508680, 0.71989304, -0.75822008, -0.33460963, 0.44296879, 0.42238355, 0.87288117, -0.15578599, 0.66007137, 0.34061113, -0.39326301, 0.17516121, 0.76495802, 0.69239485, 0.01056764, 0.17800452, -0.93094832, -0.51452005, 0.59480852, -0.17137200, -0.65398520, 0.09759752, 0.40608153, 0.34897169, -0.25059396, -0.12207674, 0.01685298, 0.55688524, 0.04187684, -0.21348982, -0.02061296, -0.94085008, -0.91302544, 0.40676415, 0.96637541, 0.18636747, -0.21280062, -0.65930158, 0.00447712, 0.96415329, 0.54104626, 0.07923490, 0.72057962, -0.53564775, 0.02754333, 0.90493482, 0.15558961, -0.08173654, -0.46144104, 0.09599262, 0.91423255, -0.98858166, 0.56731045, 0.64097184, 0.77235913, 0.48100683, 0.61827981, 0.03735657, 0.12271573, -0.14781864, -0.88775343, 0.74002033, 0.13999867, -0.60032117, 0.00944094, -0.03014978, -0.28642008, -0.30784416, 0.07695759, 0.24697889, 0.22490492, -0.08370640, -0.94405001, -0.54078996, -0.64557749, 0.16892174, 0.72201771, 0.59687787, 0.59419513, 0.63287473, -0.48941192, 0.68348968, 0.34622705, -0.83353174, -0.96661872, -0.97087997, 0.51117355, -0.50088155, -0.78102273, 0.24960417, -0.31115428, -0.86096931, -0.68074894, 0.05476080, -0.66371012, -0.45417112, 0.42317989, -0.09059674, -0.35599643, -0.05245798, -0.95273077, -0.22688580, -0.15816264, -0.62392139, -0.78247666, 0.79963702, 0.02023196, -0.58181804, 0.21129727, 0.63407934, -0.95836377, -0.96427095, -0.70707649, 0.43767095, -0.67954481, 0.40921125, 0.35635161, 0.08940433, -0.55880052, 0.95118904, 0.59562171, 0.03319904, -0.55360842, 0.29701284, -0.21020398, 0.15169193, -0.35750839, 0.26189572, -0.88242978, -0.40278813, 0.93580663, 0.75106847, -0.38722676, 0.71702880, -0.37927276, 0.87857687, 0.48768425, -0.16765547, -0.49528381, -0.98303950, 0.75743574, -0.92416686, 0.63882822, 0.92440224, 0.14056113, -0.65696579, 0.73556215, 0.94755048, 0.40804628, 0.01774749, -0.24406233, -0.30613822, -0.58847648, 0.34830603, -0.13409975, -0.61176270, -0.79115158, 0.33191505, -0.40785465, -0.00040016, -0.34930867, 0.74324304, 0.79935658, -0.96381402, -0.59829396, -0.34451860, 0.97409946, 0.56540078, -0.32180870, -0.57394040, 0.34891015, 0.67540216, 0.86437494, -0.31230038, 0.76478642, 0.37422037, -0.03100256, 0.97101647, -0.53071910, 0.45093039, -0.83063954, -0.66061169, 0.82197559, -0.57406360, 0.51823235, 0.20041765, 0.68226439, -0.26378399, -0.31942952, -0.41756943, 0.73483962, 0.20796506, 0.90861493, 0.77453023, -0.72930807, 0.10234095, -0.79145002, -0.92172438, -0.85361314, 0.73233670, 0.57623291, 0.65701193, -0.31820506, 0.23037209, 0.56380719, -0.24392074, 0.14156306, -0.55257183, -0.83651346, -0.46655273, 0.78153634, 0.12889367, 0.85013437, -0.08446148, -0.44563445, 0.57402933})},
        outputs = {radio.types.Float32.vector_from_array({-0.01284554, 0.03744585, -0.03906942, 0.01982495, -0.01068391, 0.00869445, -0.00128874, 0.00606114, -0.03026019, 0.02689551, 0.00241563, -0.01648891, 0.02748609, -0.05322693, 0.06693034, -0.05487712, 0.03563688, -0.00921246, 0.00734850, -0.03768465, 0.03617999, -0.01678194, 0.03016566, -0.04870764, 0.04121353, -0.03254537, 0.01759242, -0.01020614, 0.01744299, -0.01479517, 0.00504521, -0.00494588, 0.00434754, 0.00426579, -0.01008212, 0.00030226, 0.02837922, -0.03725865, 0.03896542, -0.05363034, 0.08008502, -0.08192987, 0.05308692, -0.04378071, 0.05590157, -0.05429924, 0.06030505, -0.07625601, 0.08790835, -0.09043160, 0.07436329, -0.06176580, 0.06995623, -0.06877317, 0.05438003, -0.04952835, 0.02830841, -0.01999889, 0.03878279, -0.05087902, 0.04061393, -0.02598476, 0.03049070, -0.03042269, 0.01882189, -0.01590310, 0.01778484, -0.00767379, -0.00164245, -0.00290103, 0.00618719, -0.02213473, 0.02184586, 0.00210509, 0.00779901, -0.02122666, 0.01346913, -0.02083918, 0.03176701, -0.01379327, 0.00587637, -0.01378212, 0.02456380, -0.04576775, 0.05405287, -0.03674160, 0.02228777, -0.02567363, 0.01810176, -0.00767391, 0.02177754, -0.05443734, 0.07985570, -0.07575626, 0.07540274, -0.07787159, 0.07754714, -0.08502727, 0.08353951, -0.08535681, 0.06936033, -0.03833003, 0.02644342, -0.03851889, 0.04787674, -0.04689018, 0.04074119, -0.03968620, 0.04505138, -0.04048203, 0.03867206, -0.04273451, 0.02612034, -0.01811900, 0.01564174, -0.00078469, 0.01047283, -0.01230310, 0.01182375, -0.01072891, -0.00936214, 0.02963646, -0.03451964, 0.01258321, -0.01447895, 0.01389542, 0.01262656, -0.02996075, 0.02398720, -0.00504046, -0.00498693, -0.00484634, 0.00784184, 0.00535365, -0.01778625, 0.02084215, -0.00469835, -0.00449173, -0.00032809, 0.00564853, -0.02126430, 0.03326746, -0.03089151, 0.02162470, -0.02365016, 0.05061074, -0.06252374, 0.04975152, -0.03407176, 0.04030135, -0.06685839, 0.06440575, -0.05762516, 0.07570934, -0.09267455, 0.10854383, -0.10565899, 0.09725777, -0.10522729, 0.12805496, -0.12980203, 0.11536229, -0.12161725, 0.13228662, -0.13654891, 0.13810875, -0.14220132, 0.14808597, -0.16298465, 0.16568407, -0.13634945, 0.12831409, -0.14380150, 0.15814683, -0.17184848, 0.18790650, -0.18817140, 0.17004883, -0.16982980, 0.15529539, -0.11926631, 0.08553715, -0.05507644, 0.05815789, -0.06988366, 0.05341912, -0.02708121, 0.02985358, -0.03828171, 0.03008080, -0.03362295, 0.03135128, -0.03520941, 0.05042798, -0.05713030, 0.04673255, -0.04824189, 0.06627487, -0.07694132, 0.08139557, -0.08466492, 0.10088226, -0.09635237, 0.06199540, -0.05339663, 0.05597853, -0.03084900, 0.02258600, -0.03737725, 0.03163516, -0.01431293, 0.01954526, -0.01553909, -0.00567634, 0.02439706, -0.03040064, 0.02221444, -0.00383251, -0.02268167, 0.03912850, -0.06026593, 0.06113538, -0.03294440, 0.00726412, 0.01217838, -0.01733327, 0.02518846, -0.04092185, 0.03850671, -0.03887782, 0.05775521, -0.06498124, 0.07500596, -0.07472618, 0.04568443, -0.02947067, 0.01273494, -0.01457594, 0.01526030, 0.01313467, -0.01541534, 0.01629274, -0.03285103, 0.04133323, -0.03402398, 0.01864007, -0.01121379, -0.00137337, -0.00366261, 0.01003267, 0.01224377, -0.02327796, 0.03512949, -0.05031246, 0.04220051, -0.02280647})}
    },
    {
        desc = "1e-6 tau, 256 Float32 input, 256 Float32 output",
        args = {1e-06},
        inputs = {radio.types.Float32.vector_from_array({-0.73127151, 0.69486749, 0.52754927, -0.48986191, -0.00912983, -0.10101787, 0.30318594, 0.57744670, -0.81228077, -0.94330502, 0.67153019, -0.13446586, 0.52456015, -0.99578792, -0.10922561, 0.44308007, -0.54247558, 0.89054137, 0.80285490, -0.93882000, -0.94910830, 0.08282494, 0.87829834, -0.23759152, -0.56680119, -0.15576684, -0.94191837, -0.55661666, -0.12422481, -0.00837552, -0.53383112, -0.53826690, -0.56243795, -0.08079307, -0.42043677, -0.95702058, 0.67515594, 0.11290865, 0.28458872, -0.62818748, 0.98508680, 0.71989304, -0.75822008, -0.33460963, 0.44296879, 0.42238355, 0.87288117, -0.15578599, 0.66007137, 0.34061113, -0.39326301, 0.17516121, 0.76495802, 0.69239485, 0.01056764, 0.17800452, -0.93094832, -0.51452005, 0.59480852, -0.17137200, -0.65398520, 0.09759752, 0.40608153, 0.34897169, -0.25059396, -0.12207674, 0.01685298, 0.55688524, 0.04187684, -0.21348982, -0.02061296, -0.94085008, -0.91302544, 0.40676415, 0.96637541, 0.18636747, -0.21280062, -0.65930158, 0.00447712, 0.96415329, 0.54104626, 0.07923490, 0.72057962, -0.53564775, 0.02754333, 0.90493482, 0.15558961, -0.08173654, -0.46144104, 0.09599262, 0.91423255, -0.98858166, 0.56731045, 0.64097184, 0.77235913, 0.48100683, 0.61827981, 0.03735657, 0.12271573, -0.14781864, -0.88775343, 0.74002033, 0.13999867, -0.60032117, 0.00944094, -0.03014978, -0.28642008, -0.30784416, 0.07695759, 0.24697889, 0.22490492, -0.08370640, -0.94405001, -0.54078996, -0.64557749, 0.16892174, 0.72201771, 0.59687787, 0.59419513, 0.63287473, -0.48941192, 0.68348968, 0.34622705, -0.83353174, -0.96661872, -0.97087997, 0.51117355, -0.50088155, -0.78102273, 0.24960417, -0.31115428, -0.86096931, -0.68074894, 0.05476080, -0.66371012, -0.45417112, 0.42317989, -0.09059674, -0.35599643, -0.05245798, -0.95273077, -0.22688580, -0.15816264, -0.62392139, -0.78247666, 0.79963702, 0.02023196, -0.58181804, 0.21129727, 0.63407934, -0.95836377, -0.96427095, -0.70707649, 0.43767095, -0.67954481, 0.40921125, 0.35635161, 0.08940433, -0.55880052, 0.95118904, 0.59562171, 0.03319904, -0.55360842, 0.29701284, -0.21020398, 0.15169193, -0.35750839, 0.26189572, -0.88242978, -0.40278813, 0.93580663, 0.75106847, -0.38722676, 0.71702880, -0.37927276, 0.87857687, 0.48768425, -0.16765547, -0.49528381, -0.98303950, 0.75743574, -0.92416686, 0.63882822, 0.92440224, 0.14056113, -0.65696579, 0.73556215, 0.94755048, 0.40804628, 0.01774749, -0.24406233, -0.30613822, -0.58847648, 0.34830603, -0.13409975, -0.61176270, -0.79115158, 0.33191505, -0.40785465, -0.00040016, -0.34930867, 0.74324304, 0.79935658, -0.96381402, -0.59829396, -0.34451860, 0.97409946, 0.56540078, -0.32180870, -0.57394040, 0.34891015, 0.67540216, 0.86437494, -0.31230038, 0.76478642, 0.37422037, -0.03100256, 0.97101647, -0.53071910, 0.45093039, -0.83063954, -0.66061169, 0.82197559, -0.57406360, 0.51823235, 0.20041765, 0.68226439, -0.26378399, -0.31942952, -0.41756943, 0.73483962, 0.20796506, 0.90861493, 0.77453023, -0.72930807, 0.10234095, -0.79145002, -0.92172438, -0.85361314, 0.73233670, 0.57623291, 0.65701193, -0.31820506, 0.23037209, 0.56380719, -0.24392074, 0.14156306, -0.55257183, -0.83651346, -0.46655273, 0.78153634, 0.12889367, 0.85013437, -0.08446148, -0.44563445, 0.57402933})},
        outputs = {radio.types.Float32.vector_from_array({-0.06015235, 0.16756663, -0.15376262, 0.04477707, 0.00213308, -0.00934061, 0.04105262, -0.01173895, -0.10450736, 0.07653672, 0.06888650, -0.12385266, 0.15768676, -0.25680459, 0.28748268, -0.19475651, 0.08164721, 0.04966090, -0.04870381, -0.10257397, 0.08485279, 0.01399066, 0.05374442, -0.13669267, 0.08712489, -0.03898106, -0.03209851, 0.05851169, -0.01331833, 0.02065671, -0.06048089, 0.05016604, -0.04390125, 0.07629762, -0.09168370, 0.03246253, 0.10713629, -0.13575973, 0.12754722, -0.18164627, 0.28446627, -0.25948158, 0.09520767, -0.04469962, 0.10130732, -0.08633409, 0.10918756, -0.17583992, 0.21402186, -0.20509009, 0.11098338, -0.04596803, 0.08692066, -0.07858980, 0.00957545, 0.00577274, -0.09604239, 0.11449626, -0.00440971, -0.05933961, 0.00987898, 0.05356935, -0.01938139, 0.01149517, -0.05892264, 0.05980049, -0.03853448, 0.07661654, -0.10637517, 0.06786917, -0.04083821, -0.04157640, 0.03702526, 0.07762813, -0.01882513, -0.04843315, 0.00763075, -0.04310330, 0.09061276, 0.00323462, -0.03750608, -0.00665152, 0.05831248, -0.15205298, 0.17336459, -0.07267185, -0.00092275, -0.01875084, -0.01556737, 0.05885925, 0.01813007, -0.17166759, 0.27140912, -0.22069924, 0.19519858, -0.18705143, 0.16757047, -0.18778783, 0.16391544, -0.15920238, 0.07214633, 0.07361889, -0.11086363, 0.03172832, 0.02364877, -0.02301483, -0.00185152, -0.00021537, 0.03183265, -0.01261024, 0.00871994, -0.03267089, -0.04347340, 0.06949244, -0.06667947, 0.12270816, -0.05702478, 0.03734973, -0.03142583, 0.02943751, -0.11691077, 0.19415687, -0.18995754, 0.06166314, -0.06246603, 0.05183895, 0.07859888, -0.14891705, 0.10137442, 0.00007961, -0.04619294, -0.00663271, 0.02036596, 0.04348551, -0.09543092, 0.09696725, -0.00884630, -0.03487087, 0.00730307, 0.01886661, -0.08981670, 0.13474654, -0.10692582, 0.05102297, -0.05567127, 0.17665279, -0.21170254, 0.12735148, -0.04116087, 0.06916619, -0.18877727, 0.15723477, -0.11021130, 0.18624367, -0.24750295, 0.29634318, -0.25193855, 0.18853268, -0.21083586, 0.30035785, -0.28019261, 0.18783359, -0.20520139, 0.24141254, -0.24341893, 0.23314156, -0.23667181, 0.24868633, -0.30190286, 0.29168949, -0.13359329, 0.09641923, -0.17418985, 0.23636609, -0.28765917, 0.34380227, -0.31939557, 0.21294400, -0.20486143, 0.13103735, 0.03368679, -0.16646875, 0.26764986, -0.20012707, 0.10272671, -0.15142903, 0.24106221, -0.18396644, 0.10932321, -0.12344285, 0.08159898, -0.07328096, 0.03800083, 0.04530796, -0.07753550, 0.02548857, -0.03605136, 0.12250071, -0.16319896, 0.16986646, -0.17062122, 0.23242182, -0.18956932, 0.01334897, 0.01891379, 0.00507265, 0.10422770, -0.12069915, 0.02786303, -0.04401881, 0.11268818, -0.06729304, 0.07176673, -0.15675010, 0.21956059, -0.21556658, 0.14677027, -0.04020116, -0.08994107, 0.15589221, -0.23566405, 0.21087994, -0.05423367, -0.06952283, 0.14793453, -0.14973971, 0.16474074, -0.21545781, 0.17543465, -0.15464583, 0.22399831, -0.23048659, 0.25020173, -0.22006936, 0.06016326, 0.01814358, -0.08867945, 0.06337440, -0.04734576, 0.17001249, -0.15488365, 0.13604772, -0.19388452, 0.20711215, -0.14561178, 0.05521511, -0.01442261, -0.04504771, 0.01428047, 0.01850080, 0.08720716, -0.12654488, 0.16505367, -0.21477720, 0.14973418, -0.04122606})}
    },
}, {epsilon = 1.0e-06})