-- Do not edit! This file was generated by blocks/signal/sampler_spec.py

local radio = require('radio')
local jigs = require('tests.jigs')

jigs.TestBlock(radio.SamplerBlock, {
    {
        desc = "256 ComplexFloat32 data, 256 Float32 clock, 256 Float32 output",
        args = {},
        inputs = {radio.types.ComplexFloat32.vector_from_array({{-0.73127151, 0.69486749}, {0.52754927, -0.48986191}, {-0.00912983, -0.10101787}, {0.30318594, 0.57744670}, {-0.81228077, -0.94330502}, {0.67153019, -0.13446586}, {0.52456015, -0.99578792}, {-0.10922561, 0.44308007}, {-0.54247558, 0.89054137}, {0.80285490, -0.93882000}, {-0.94910830, 0.08282494}, {0.87829834, -0.23759152}, {-0.56680119, -0.15576684}, {-0.94191837, -0.55661666}, {-0.12422481, -0.00837552}, {-0.53383112, -0.53826690}, {-0.56243795, -0.08079307}, {-0.42043677, -0.95702058}, {0.67515594, 0.11290865}, {0.28458872, -0.62818748}, {0.98508680, 0.71989304}, {-0.75822008, -0.33460963}, {0.44296879, 0.42238355}, {0.87288117, -0.15578599}, {0.66007137, 0.34061113}, {-0.39326301, 0.17516121}, {0.76495802, 0.69239485}, {0.01056764, 0.17800452}, {-0.93094832, -0.51452005}, {0.59480852, -0.17137200}, {-0.65398520, 0.09759752}, {0.40608153, 0.34897169}, {-0.25059396, -0.12207674}, {0.01685298, 0.55688524}, {0.04187684, -0.21348982}, {-0.02061296, -0.94085008}, {-0.91302544, 0.40676415}, {0.96637541, 0.18636747}, {-0.21280062, -0.65930158}, {0.00447712, 0.96415329}, {0.54104626, 0.07923490}, {0.72057962, -0.53564775}, {0.02754333, 0.90493482}, {0.15558961, -0.08173654}, {-0.46144104, 0.09599262}, {0.91423255, -0.98858166}, {0.56731045, 0.64097184}, {0.77235913, 0.48100683}, {0.61827981, 0.03735657}, {0.12271573, -0.14781864}, {-0.88775343, 0.74002033}, {0.13999867, -0.60032117}, {0.00944094, -0.03014978}, {-0.28642008, -0.30784416}, {0.07695759, 0.24697889}, {0.22490492, -0.08370640}, {-0.94405001, -0.54078996}, {-0.64557749, 0.16892174}, {0.72201771, 0.59687787}, {0.59419513, 0.63287473}, {-0.48941192, 0.68348968}, {0.34622705, -0.83353174}, {-0.96661872, -0.97087997}, {0.51117355, -0.50088155}, {-0.78102273, 0.24960417}, {-0.31115428, -0.86096931}, {-0.68074894, 0.05476080}, {-0.66371012, -0.45417112}, {0.42317989, -0.09059674}, {-0.35599643, -0.05245798}, {-0.95273077, -0.22688580}, {-0.15816264, -0.62392139}, {-0.78247666, 0.79963702}, {0.02023196, -0.58181804}, {0.21129727, 0.63407934}, {-0.95836377, -0.96427095}, {-0.70707649, 0.43767095}, {-0.67954481, 0.40921125}, {0.35635161, 0.08940433}, {-0.55880052, 0.95118904}, {0.59562171, 0.03319904}, {-0.55360842, 0.29701284}, {-0.21020398, 0.15169193}, {-0.35750839, 0.26189572}, {-0.88242978, -0.40278813}, {0.93580663, 0.75106847}, {-0.38722676, 0.71702880}, {-0.37927276, 0.87857687}, {0.48768425, -0.16765547}, {-0.49528381, -0.98303950}, {0.75743574, -0.92416686}, {0.63882822, 0.92440224}, {0.14056113, -0.65696579}, {0.73556215, 0.94755048}, {0.40804628, 0.01774749}, {-0.24406233, -0.30613822}, {-0.58847648, 0.34830603}, {-0.13409975, -0.61176270}, {-0.79115158, 0.33191505}, {-0.40785465, -0.00040016}, {-0.34930867, 0.74324304}, {0.79935658, -0.96381402}, {-0.59829396, -0.34451860}, {0.97409946, 0.56540078}, {-0.32180870, -0.57394040}, {0.34891015, 0.67540216}, {0.86437494, -0.31230038}, {0.76478642, 0.37422037}, {-0.03100256, 0.97101647}, {-0.53071910, 0.45093039}, {-0.83063954, -0.66061169}, {0.82197559, -0.57406360}, {0.51823235, 0.20041765}, {0.68226439, -0.26378399}, {-0.31942952, -0.41756943}, {0.73483962, 0.20796506}, {0.90861493, 0.77453023}, {-0.72930807, 0.10234095}, {-0.79145002, -0.92172438}, {-0.85361314, 0.73233670}, {0.57623291, 0.65701193}, {-0.31820506, 0.23037209}, {0.56380719, -0.24392074}, {0.14156306, -0.55257183}, {-0.83651346, -0.46655273}, {0.78153634, 0.12889367}, {0.85013437, -0.08446148}, {-0.44563445, 0.57402933}, {0.65553629, -0.97523654}, {0.34082329, -0.81663376}, {-0.76979506, 0.77012014}, {-0.91995299, -0.52073330}, {0.97631699, -0.15797283}, {-0.76888371, -0.66523314}, {-0.51715940, 0.48801285}, {-0.79433179, 0.82152885}, {-0.24344546, 0.94052809}, {0.81844544, -0.41195285}, {-0.49317971, -0.04597981}, {-0.79974169, 0.30410039}, {-0.92075950, -0.97898769}, {0.96516722, -0.40890029}, {0.19314128, -0.10031093}, {-0.37343827, -0.87407041}, {0.82678401, 0.93962657}, {0.93959302, -0.77727538}, {-0.56961346, 0.23561376}, {0.95990574, 0.08582640}, {0.37637961, 0.32366887}, {-0.48182800, 0.08320452}, {-0.38535777, -0.50723761}, {-0.83726245, -0.43842655}, {0.96675342, -0.10419552}, {0.30402106, 0.28693217}, {0.88146901, -0.21904290}, {-0.38643140, -0.34551716}, {-0.36652973, 0.69426954}, {0.78700048, -0.39438137}, {-0.33133319, 0.08845083}, {0.15797088, 0.19192508}, {-0.50980401, -0.95925194}, {-0.51248139, -0.85534495}, {0.10240951, -0.85816729}, {-0.84974039, 0.27076420}, {-0.41835687, 0.58436954}, {-0.01347791, 0.72529793}, {-0.69164079, 0.00285917}, {0.58996701, -0.84578598}, {0.89845592, -0.65351576}, {0.55241799, 0.96979177}, {0.64310026, -0.36043200}, {-0.78624445, 0.02871650}, {0.83871394, -0.41302100}, {0.78751761, -0.71663874}, {0.82096338, -0.93648010}, {-0.36786264, 0.80617654}, {0.60771257, 0.81430751}, {0.68143702, 0.49236977}, {0.37919036, -0.64369029}, {-0.13472399, -0.68420619}, {0.42964891, 0.33555749}, {-0.49482721, -0.87117159}, {0.92677176, 0.61650527}, {0.09853987, 0.08275530}, {0.70258534, -0.09338064}, {-0.20857909, -0.32266170}, {-0.48406181, -0.95118302}, {0.29287767, -0.16663224}, {0.14120726, -0.87535673}, {-0.29011312, -0.72343177}, {-0.74974197, -0.48177409}, {0.65786874, -0.20440537}, {-0.19783570, 0.22488984}, {-0.53294069, -0.98504567}, {0.05740348, 0.00179924}, {0.29767919, -0.12336609}, {0.37302625, 0.46284387}, {-0.52325064, -0.00985550}, {-0.04234622, -0.54987586}, {-0.17550774, 0.12081487}, {0.81387901, 0.83541310}, {-0.44954929, 0.29283035}, {-0.90360534, -0.85689718}, {0.02338342, 0.75484818}, {-0.68106455, 0.53205574}, {0.76601923, -0.37639597}, {0.38511392, 0.69798225}, {-0.25677133, 0.40256533}, {0.47283623, 0.18915559}, {0.71255422, 0.79320872}, {0.92015761, 0.14246538}, {-0.64744818, -0.49880919}, {-0.56476265, 0.13903470}, {0.51550025, -0.89573354}, {0.36327291, 0.43430653}, {-0.30403697, 0.03011161}, {-0.67040372, 0.45979229}, {-0.91858262, 0.96244210}, {0.61588746, 0.25689700}, {-0.46494752, 0.82572573}, {0.91887766, -0.72174770}, {0.55151451, 0.68386173}, {0.31943470, 0.40081555}, {-0.10988253, 0.84861559}, {0.94241506, -0.23529337}, {0.60542303, -0.13415682}, {-0.67049158, -0.34906545}, {-0.74733984, 0.81776953}, {0.91884816, -0.76162654}, {0.20135815, -0.18355180}, {-0.76381993, -0.40904897}, {-0.50356728, 0.49915361}, {-0.99198210, -0.62032259}, {-0.12245386, -0.95793062}, {0.25505316, 0.21125507}, {0.67066473, -0.58678836}, {-0.43043676, 0.08467886}, {-0.45354861, 0.17147619}, {-0.49823555, 0.36705431}, {0.58218145, 0.61730921}, {0.94723225, 0.09075401}, {-0.01838144, 0.71139538}, {0.53813475, 0.14108926}, {-0.23348723, -0.43190512}, {-0.78372163, 0.61509818}, {-0.76385695, 0.49453047}, {0.09057418, 0.92989063}, {0.52213132, 0.94703954}, {-0.72681195, 0.00074295}, {0.14515658, -0.37749708}, {0.00606498, -0.28636247}, {0.05678794, -0.99831057}, {-0.11537134, -0.10089571}, {-0.39040163, -0.20119449}, {0.56617463, 0.36682576}, {-0.01540173, 0.29533648}}), radio.types.Float32.vector_from_array({-0.24488358, -0.59217191, -0.99224871, -0.44475749, 0.19632840, 0.76332581, 0.65884250, 0.02192042, 0.97403622, -0.07683806, 0.66918695, -0.18206932, 0.48926124, 0.97518337, -0.38932681, -0.65937436, 0.24006742, 0.06191236, -0.28115594, -0.99296153, -0.22167473, -0.14826106, -0.18949586, 0.72249067, 0.16885605, 0.46766159, 0.79581833, 0.49754697, -0.01459590, 0.49153668, 0.28071079, 0.29749086, 0.25935072, -0.18600205, 0.25852406, 0.26746503, 0.87423593, 0.56494737, 0.69253606, 0.53499961, 0.63065171, 0.21092477, -0.30109984, -0.47083348, 0.41604009, 0.74788415, 0.08849352, -0.69586009, 0.66595060, -0.03091384, -0.06579474, -0.90922385, 0.02056185, 0.48949531, -0.15480438, -0.28964537, 0.31368709, -0.96051723, 0.01432719, 0.89225417, 0.38089520, -0.19615254, 0.37781647, 0.20998783, -0.58222121, -0.58458334, 0.77205056, -0.46186161, -0.85023046, 0.66135520, 0.04639554, -0.26358366, 0.02303784, 0.47345135, -0.66289276, 0.30613399, 0.42687401, 0.63000691, -0.46047872, 0.21933267, -0.53577226, 0.12208935, -0.65527403, 0.57953525, 0.73343575, -0.34071288, -0.55536288, 0.92757678, 0.41338065, 0.68758518, -0.93893105, 0.79878664, 0.24490412, -0.36694169, -0.13646875, 0.52318597, 0.57082391, -0.62019825, 0.25177300, -0.66874093, 0.94609958, -0.11284689, 0.82629001, 0.45649573, 0.21251979, -0.47603193, 0.05318464, -0.72276050, -0.72380400, 0.43149957, -0.27782047, 0.50275260, -0.51901281, 0.43631628, 0.43695384, -0.38900825, -0.78722912, -0.20598429, -0.01527700, -0.80005163, -0.62647748, -0.88931382, 0.19502714, 0.77775222, -0.56688440, -0.93057311, 0.40784720, 0.62982112, 0.92824322, 0.22635791, -0.31511366, 0.67573726, -0.76386577, 0.38527387, -0.80953830, -0.20058849, -0.00995424, -0.24421147, -0.66280484, -0.53656536, 0.64029998, -0.07484839, 0.15986548, -0.57618594, 0.42987013, -0.33976549, 0.18723717, 0.81897414, 0.98878682, -0.90756410, 0.59488541, 0.71517563, -0.36085111, -0.23370475, 0.16050752, 0.83768046, -0.20014282, 0.76006031, 0.51712108, -0.69545382, 0.82735986, -0.96963781, -0.70964354, 0.32962242, -0.88576066, -0.24102025, -0.74004227, -0.07422146, 0.67996067, 0.81216872, -0.92906070, -0.87829649, 0.68124807, -0.91437042, -0.45281947, -0.76512659, -0.81792456, -0.94475424, 0.27502602, 0.48922855, 0.37354276, 0.69124550, 0.32603237, -0.22059613, 0.26212606, 0.93918961, 0.28320667, -0.51381654, -0.87963182, 0.87033200, 0.18099099, -0.30077052, 0.21070550, 0.12051519, 0.04434354, -0.87839073, -0.29354489, -0.17469995, -0.60126334, 0.76021045, -0.15176044, 0.32477134, 0.42709291, 0.48656613, 0.44223061, 0.50441700, -0.49683860, 0.95280737, -0.69798046, 0.83729482, 0.70913750, 0.70432854, -0.89437741, -0.81756383, 0.62611163, -0.06166634, -0.25949362, 0.96937495, -0.91976410, 0.06293010, -0.11330045, -0.74359375, -0.20962349, 0.41529480, 0.76463121, -0.95076066, 0.04901912, -0.81924683, 0.60078692, -0.82842946, -0.93161339, -0.23152760, 0.46521235, -0.37358665, -0.73999017, 0.58914447, 0.61383879, 0.71171957, -0.39251104, -0.15033928, -0.50922000, 0.11435498, -0.33978567, -0.32267332, 0.56724286, 0.91259229, 0.16828065, -0.79062414, 0.30514985, -0.10277656, 0.97606111, 0.43876299, 0.66957223, 0.40257251, 0.07123801, 0.79363680})},
        outputs = {radio.types.ComplexFloat32.vector_from_array({{-0.81228077, -0.94330502}, {-0.94910830, 0.08282494}, {-0.56680119, -0.15576684}, {-0.56243795, -0.08079307}, {0.87288117, -0.15578599}, {0.59480852, -0.17137200}, {0.04187684, -0.21348982}, {-0.46144104, 0.09599262}, {0.61827981, 0.03735657}, {0.00944094, -0.03014978}, {-0.94405001, -0.54078996}, {0.72201771, 0.59687787}, {-0.96661872, -0.97087997}, {-0.68074894, 0.05476080}, {-0.35599643, -0.05245798}, {-0.78247666, 0.79963702}, {-0.95836377, -0.96427095}, {-0.55880052, 0.95118904}, {-0.55360842, 0.29701284}, {-0.35750839, 0.26189572}, {-0.37927276, 0.87857687}, {0.63882822, 0.92440224}, {-0.24406233, -0.30613822}, {-0.79115158, 0.33191505}, {-0.34930867, 0.74324304}, {-0.59829396, -0.34451860}, {0.86437494, -0.31230038}, {-0.53071910, 0.45093039}, {0.82197559, -0.57406360}, {0.68226439, -0.26378399}, {0.56380719, -0.24392074}, {0.85013437, -0.08446148}, {-0.91995299, -0.52073330}, {-0.76888371, -0.66523314}, {-0.92075950, -0.97898769}, {0.19314128, -0.10031093}, {0.82678401, 0.93962657}, {-0.56961346, 0.23561376}, {-0.38535777, -0.50723761}, {0.88146901, -0.21904290}, {0.78700048, -0.39438137}, {-0.50980401, -0.95925194}, {-0.84974039, 0.27076420}, {0.89845592, -0.65351576}, {0.83871394, -0.41302100}, {0.37919036, -0.64369029}, {0.70258534, -0.09338064}, {-0.29011312, -0.72343177}, {-0.19783570, 0.22488984}, {-0.17550774, 0.12081487}, {-0.44954929, 0.29283035}, {-0.25677133, 0.40256533}, {0.71255422, 0.79320872}, {0.36327291, 0.43430653}, {-0.91858262, 0.96244210}, {-0.46494752, 0.82572573}, {-0.10988253, 0.84861559}, {-0.67049158, -0.34906545}, {0.91884816, -0.76162654}, {-0.99198210, -0.62032259}, {0.67066473, -0.58678836}, {-0.01838144, 0.71139538}, {-0.78372163, 0.61509818}, {-0.72681195, 0.00074295}, {0.00606498, -0.28636247}})}
    },
    {
        desc = "256 Float32 data, 256 Float32 clock, 256 Float32 output",
        args = {},
        inputs = {radio.types.Float32.vector_from_array({0.66323411, -0.41734824, -0.68593621, -0.25929627, 0.04215534, -0.80523974, -0.30924141, 0.14981133, -0.91285074, 0.62989736, 0.30223408, -0.37269965, -0.40335804, -0.29476771, -0.34942260, 0.49702755, 0.00211372, 0.05225680, -0.70248693, 0.82883602, -0.34885415, -0.34487113, -0.86230779, 0.95882314, -0.04060432, 0.82576954, 0.85523450, 0.93950427, 0.63125855, 0.85088646, 0.84457862, 0.60273534, -0.73083758, 0.04742344, 0.15120803, 0.98499507, 0.56789708, 0.40583244, 0.49329808, -0.27684447, 0.88462710, 0.28700179, -0.19485077, -0.07085684, 0.95950985, 0.06425680, -0.66440493, -0.70328999, 0.37448439, 0.12555106, 0.81361258, -0.63079929, -0.17778239, 0.45592043, -0.89978993, -0.80155522, 0.09141580, -0.46854156, -0.78612483, -0.47660485, 0.26428217, 0.05275488, -0.84300649, -0.85437709, 0.70125401, 0.28647792, -0.65326548, 0.72366816, -0.95630121, -0.26379043, 0.69525945, 0.42055681, -0.43249515, 0.78256297, 0.19615600, 0.73098665, 0.78558677, -0.14911185, 0.35120067, 0.08895263, 0.88947046, 0.59632146, 0.45163700, 0.62806475, 0.99631995, -0.48687765, -0.59727275, 0.49356559, 0.54066503, 0.02856760, -0.02584837, -0.19251385, 0.76539385, 0.59246373, 0.16919520, -0.91976184, 0.70228320, -0.08309264, -0.62047893, -0.40129143, 0.38266897, -0.98898584, -0.75991070, -0.39469272, 0.77438271, 0.49372089, 0.94158345, 0.08605748, 0.14393646, 0.10275362, 0.05125443, 0.08408114, 0.63713509, 0.90673745, -0.18339846, 0.25993049, -0.38448119, -0.39617923, 0.01263470, 0.17253532, 0.09998894, 0.95315933, -0.67405754, 0.27332884, 0.98906201, 0.47227055, 0.13181703, -0.26327369, -0.19572224, 0.87304616, 0.79066086, 0.33935255, 0.79749578, 0.85032725, 0.69268709, -0.23316762, -0.07127071, 0.59181499, -0.25473395, 0.49872759, -0.03715924, -0.32691738, -0.08770342, -0.76698107, -0.29100648, -0.16961114, -0.96367288, -0.65585208, -0.47953391, 0.71576798, 0.17915428, -0.42571020, 0.99545342, -0.48415881, 0.02757668, 0.47903955, 0.38264108, -0.13299464, 0.55399537, -0.02841179, 0.43093011, -0.01724692, 0.94298935, 0.43235987, -0.81724554, -0.74105978, 0.93302959, -0.54154325, -0.94772792, -0.49355251, -0.04042588, 0.90433711, -0.20174021, 0.44701117, 0.66872507, -0.82167590, 0.22378393, 0.99156874, 0.09919193, 0.06897236, -0.30659491, 0.89221078, 0.93919849, -0.79366034, 0.10566772, -0.16074154, 0.34329233, -0.76270670, -0.46933141, -0.44249323, -0.04057412, 0.58656567, 0.71569502, 0.57284731, 0.35361367, -0.82561445, -0.22056586, 0.33740324, -0.41150445, 0.01563679, 0.81015670, -0.76768589, 0.70775330, -0.78834063, -0.22727112, 0.81077880, -0.59759986, 0.04148525, -0.16679193, 0.77589458, 0.98412937, -0.42281488, -0.01504692, 0.79001021, 0.08959135, -0.57075012, 0.51932460, -0.32582140, -0.02805126, -0.98287618, 0.97793406, 0.31456473, 0.85162568, 0.93737054, -0.46493265, 0.08107195, -0.11949753, 0.51971042, 0.68477136, -0.54287970, -0.45087069, 0.41252309, -0.17671390, -0.73959690, -0.60937881, 0.12169863, 0.19698890, 0.92014313, 0.06555991, 0.21796153, -0.70229048, -0.17239615, -0.44041741, 0.39084569, -0.46588549, -0.57119936, -0.26463121, -0.05890188, -0.32321006, 0.21146432, -0.63759267, 0.75982058, 0.38834271, 0.06952644, -0.88367546, -0.34798673}), radio.types.Float32.vector_from_array({0.38021475, 0.29012856, 0.62390834, 0.78301710, -0.36926723, -0.01253863, -0.33991677, -0.74415547, -0.71976584, -0.48706111, -0.82394248, 0.07765107, 0.40584487, 0.12614518, 0.36953351, -0.54750401, -0.60119128, 0.13514970, 0.76857120, -0.15547091, -0.99152672, -0.95989680, -0.38939083, 0.23074846, -0.83086914, -0.55097932, 0.36138111, 0.96998382, -0.31785437, 0.20227797, 0.03685967, -0.95375037, -0.34033117, -0.72111762, -0.49835664, 0.53996199, 0.36240515, -0.91795415, -0.84524977, 0.44985843, -0.79358053, -0.36596003, -0.46132475, -0.90046698, -0.93765998, -0.72193050, -0.20134553, 0.86741143, 0.27675626, -0.51587802, 0.35928836, -0.45273361, 0.03047603, -0.35634464, 0.89734185, -0.29527497, 0.60712558, 0.28238592, 0.68665117, 0.21232074, 0.74076998, -0.18967403, 0.35800537, 0.24127433, 0.05546742, 0.12887995, 0.07152396, -0.21245857, 0.79663879, 0.26545882, 0.09824614, -0.89212191, 0.01705623, -0.64970654, -0.56995356, -0.13077547, 0.09191364, -0.49917573, -0.45813125, 0.06029268, -0.05353185, -0.19342501, -0.79249299, -0.25304469, 0.30884251, 0.08839788, 0.08950543, 0.68763614, 0.44632611, 0.36917847, -0.93917274, -0.38374409, 0.36482465, -0.68845451, 0.82694608, -0.71614695, 0.75824291, -0.56746328, 0.68317950, 0.69645935, -0.32907057, 0.77718472, -0.68046439, 0.69821906, -0.23653090, -0.12056480, -0.76428038, 0.20201053, -0.46048835, 0.33375859, 0.59877586, 0.20736805, -0.98363030, 0.90467048, 0.83936232, 0.28587064, -0.24098730, 0.12382753, 0.76562417, -0.08094239, 0.55843651, 0.19711781, -0.15544155, 0.86705309, -0.18313821, 0.21155824, -0.89345133, -0.05847226, -0.92517149, 0.40826571, -0.99881953, -0.91586888, -0.77774882, -0.72085023, 0.01615673, -0.28742319, -0.45819339, 0.96724719, 0.81799984, 0.30972469, 0.60417396, 0.63941675, -0.50965315, 0.61657214, -0.52037674, 0.12471312, -0.28456599, -0.68268162, 0.55370885, 0.83268338, -0.37260288, 0.75952506, -0.30748782, 0.31511071, 0.99157917, 0.54414147, -0.88866550, -0.13025467, -0.24739347, -0.41213641, 0.63227111, -0.11795960, 0.39848059, 0.26986226, 0.03799157, -0.88793755, 0.34607047, 0.78276616, -0.65560114, 0.28548884, -0.02512130, -0.31803083, 0.42085344, 0.95039791, -0.95667064, 0.79461151, -0.23352271, 0.66769671, -0.65057725, 0.43318319, -0.80060703, -0.32877967, 0.93981737, 0.31323102, 0.56904751, -0.07738914, -0.05766606, -0.01474971, 0.54631060, 0.44649959, -0.61246377, -0.11879122, 0.08404784, 0.14285728, 0.85354191, 0.67949438, -0.70023751, -0.24775857, -0.78205502, -0.94755238, -0.85082805, -0.63406891, 0.53215438, 0.33444285, 0.59574193, -0.42299321, -0.68897790, 0.94420046, 0.65204984, 0.89356416, -0.96242583, -0.20690504, 0.26759642, 0.47214916, 0.82530117, 0.07546358, -0.21841520, -0.98935199, 0.60772651, 0.96431583, 0.81449288, 0.32453701, -0.31504908, -0.52169949, 0.55003935, 0.87085873, 0.92065221, -0.64878523, 0.17070550, 0.02623654, -0.14514965, 0.58880138, 0.87156475, 0.44924963, 0.40061173, 0.38122904, 0.30711341, 0.07350796, -0.50416857, 0.55895406, -0.76181310, 0.28777635, -0.22602537, 0.11992508, 0.28287268, -0.04215294, 0.95618826, -0.52161390, -0.97566330, 0.91051602, -0.37598455, -0.44385484, -0.16888189, 0.18993346, 0.97222912, 0.41504937})},
        outputs = {radio.types.Float32.vector_from_array({0.66323411, -0.37269965, 0.05225680, 0.95882314, 0.85523450, 0.85088646, 0.98499507, -0.27684447, -0.70328999, 0.81361258, -0.17778239, -0.89978993, 0.09141580, -0.84300649, -0.95630121, -0.43249515, 0.78558677, 0.08895263, 0.99631995, 0.76539385, 0.16919520, 0.70228320, -0.62047893, -0.98898584, -0.39469272, 0.08605748, 0.10275362, 0.90673745, -0.39617923, 0.09998894, 0.27332884, 0.47227055, 0.87304616, 0.69268709, 0.59181499, -0.76698107, -0.16961114, -0.47953391, -0.42571020, -0.48415881, 0.43093011, 0.94298935, 0.93302959, -0.49355251, -0.20174021, -0.82167590, 0.99156874, 0.06897236, 0.93919849, -0.46933141, 0.71569502, 0.70775330, 0.04148525, -0.01504692, -0.02805126, -0.46493265, 0.68477136, 0.41252309, 0.21796153, -0.17239615, 0.39084569, -0.26463121, 0.21146432, 0.06952644})}
    },
}, {epsilon = 1.0e-06})
