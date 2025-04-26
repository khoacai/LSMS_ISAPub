/*===================================================
*
* A PROJECT OF MEASURING HOUSEHOLD INCOME AND EXPENDITURE IN MALAWI (2023)
* 
* Purpose:  A program to calculate the income and expenditure measures
* from Worldbank LSMS-ISA data project
* Language:	Stata for Windows
* Authors:	Khoa Cai
* Date:		April 2023
*
*===================================================*/

clear all

cd "D:\02_WB_LSMS_ISA\03_Malawi\04_2019~2020.IHS5(P)\MWI_2019_IHS-V_v05_M_Stata\"

/*
This part collects data at the household level:
0. SAMPLING WEIGHTS AND SURVEY TECHNICAL VARIABLES
1. HOUSEHOLD CONSUMPTION:
1.1. Food consmption
1.2. Apparel consumption
1.3. Monthly consumption
1.4. Yearly nondurable consumption
1.5. Durable consumption
2. HOUSEHOLD INCOME
2.1 Business income 
*BỎ 2.2 Agricultural, fishing, forestry and hunting income: this should be flexible, based on country specifics.
2.3 Other income 
2.4 Taxes, transfers?
3. HOUSEHOLD DEMOGRAPHICS
3.1. Ethnicity (language speak), religion 
3.2. Localtion of residence: State, district, rural/urban.
4. INDIVIDUALS
4.1. Demographics: Sex, age, relationship to the household head, marital status 
4.2. Education: Schooling or not, highest level of education.
4.3. Main job: Sector (government, private, foreign direct investment, ...), industry (ISIC rev. 4), occupation (ISCO 08), hours worked per week (month), days per week (month), income (frequency? gross/net)
4.4. Other jobs: income 
*/

use HH_MOD_A_FILT, clear
/*Merging the modules: 
Household (Indentification, and Roster) 
Individual (Education, Health, and Time Use & Labor)
*/
merge 1:m case_id using HH_MOD_B, nogen
foreach file in HH_MOD_C HH_MOD_D HH_MOD_E {
merge 1:1 case_id PID using `file', nogen
}

****************INDIVIDUAL IDENTIFICATION***************************************
//naming the variables in comprehensive formats for more consistence with 
//later waves of data survey (i.e. 2011, and 2016).

//"Survey Solutions" Unique HH Identifier (in long serial numbers), 
//e.g. c58e3284fee84a598b22086985e8212a
rename HHID hhid_ihs_surveysolutions 

//Unique Household Identifier in short serial figures, e.g. 101010160009
rename case_id hhid_ihs_serial 

//pid, Household Member ID Code in a sequential formal, is already defined in the survey dataset, e.g. 1 or 2 or 3 and so on until the last member of a household's roster
rename PID pid_seq

gen location_urban = reside == 1
//household size variable is already defined in IHS5
//by hhid_ihs_serial, sort: egen float hhsize = count(pid_seq) 
gen pweight = hh_wgt*hhsize /*this is followed by survey methodology */
rename hh_b06a demo_birthmonth
rename hh_b06b demo_birthyear
gen demo_sex = hh_b03 == 1
copydesc hh_b03 demo_sex
rename hh_b05a demo_age
rename hh_b24 demo_marital
rename hh_c06 demo_school_attended
rename hh_c10 demo_schoolingstartage
rename hh_c15 demo_school_lastattend
gen yearsofschooling = demo_school_lastattend - (demo_birthyear + demo_schoolingstartage) + 1
replace yearsofschooling = . if demo_school_attended == .
replace yearsofschooling = 0 if demo_school_attended == 0
rename hh_c09 education_highest

********************************************************************************
****************INDIVIDUAL INCOME***********************************************
********************************************************************************

****************A. INDIVIDUAL INCOME - FIRST(MAIN) JOB**************************
/* Normally, industrial activities and occupations are classified based on 
international standards developed by the United Nations.
*/
rename hh_e20b mainjob_activities_code
rename hh_e19b mainjob_occupations_code

***A.1 INDIVIDUAL MAIN JOB - INDUSTRY CODES
/*
MAPPING
(Section Divisions Description)
Industrial codes according to LSMS_ISA for "this specific dataset" (Malawi in 2019~2020) @https://microdata.worldbank.org/index.php/catalog/2936/download/47116, page #38
(Code Description)
TO
Industries according to ISIC revision 4 @https://unstats.un.org/unsd/classifications/Econ/Download/In%20Text/ISIC_Rev_4_publication_English.pdf, page #59
*/

*A.1.A. AGRICULTURE, HUNTING, FORESTRY & FISHING
/*
*01 Growing of non-perennial crops (cereals, rice, vegetables, sugar cane, tobacco)
Growing of perennial crops (grapes, citrus fruits, other fruits, beverage crops, spices)
Plant propagation
Animal Production (cattle, horses, camels, sheep, goats, swine/pigs, poultry)
Mixed farming
Support activities to agriculture & post-harvest crop activities (activities for crop production
& animal production, seed processing for propagation).
*02 Forestry and logging (silviculture, gathering of non-wood forest product
*03 Fishing and aquaculture (marine and freshwater fishing and aquaculture)
*/
*-->
*A 01–03 Agriculture, forestry and fishing
gen mainjob_ind_a = (mainjob_activities_code>0.5 & mainjob_activities_code<3.5)

*A.1.B. MINING AND QUARRYING
/*
*05 Mining of coal and lignite
*06 Extraction of crude petroleum and natural gas
*07 Mining of metal ores (iron, non-ferrous metal ores, uranium, thorium)
*08 Other mining and quarrying (stone, sand, clay, chemical and fertilizer minerals, extraction of
peat, salt)
*09 Mining support service activities (for petroleum, natural gas extraction, other mining and
quarrying support activities)
*/
*-->
*B 05–09 Mining and quarrying
gen mainjob_ind_b = (mainjob_activities_code>4.5 & mainjob_activities_code<9.5)

*A.1.C. MANUFACTURING
/*
*10 Processing and preserving of meat
Processing and preserving of fish, crustaceans and molluscs
Processing and preserving of fruit and vegetables
Manufacture of vegetable and animal oils and fats
Manufacture of dairy products
Manufacture of grain mill products, starches and starch products
Manufacture of grain mill products
Manufacture of bakery products
Manufacture of sugar
Manufacture of cocoa, chocolate and sugar confectionery
Manufacture of macaroni, noodles, couscous and similar farinaceous products
Manufacture of prepared meals and dishes
Manufacture of other food products n.e.c.
Manufacture of prepared animal feeds
*11 Distilling, rectifying and blending of spirits
Manufacture of wines
Manufacture of malt liquors and malt
Manufacture of soft drinks; production of mineral waters and other bottled waters
*12 Manufacture of tobacco products
*13 Preparation and spinning of textile fibres
Weaving of textiles
Finishing of textiles
Manufacture of knitted and crocheted fabrics
Manufacture of made-up textile articles, except apparel
Manufacture of carpets and rugs
Manufacture of cordage, rope, twine and netting
Manufacture of other textiles n.e.c.
*14 Manufacture of wearing apparel, except fur apparel
Manufacture of articles of fur
Manufacture of knitted and crocheted apparel
*15 Tanning and dressing of leather; dressing and dyeing of fur
Manufacture of luggage, handbags and the like, saddlery and harness
Manufacture of footwear
*16 Manufacture of wood and of products of wood and cork, except furniture;
manufacture of articles of straw and plaiting materials
*17 Manufacture of paper and paper products
*18 Printing
Service activities related to printing
Reproduction of recorded media
*19 Manufacture of coke and refined petroleum products
*20 Manufacture of basic chemicals, fertilizers and nitrogen compounds, plastics and synthetic
rubber in primary forms, Manufacture of other chemical products (pesticides, paints,
varnishes, printing ink, soap and detergents, man-made fibres
*21 Manufacture of pharmaceuticals, medicinal chemical and botanical products
*22 Manufacture of rubber and plastics products
*23 Manufacture of glass and glass products, Manufacture of refractory products
Manufacture of clay building materials
Manufacture of other porcelain and ceramic products
Manufacture of cement, lime and plaster
Manufacture of articles of concrete, cement and plaster
Cutting, shaping and finishing of stone
*24 Manufacture of basic iron and steel
Manufacture of basic precious and other non-ferrous metals
Casting of iron and steel
Casting of non-ferrous metals
*25 Manufacture of fabricated metal products, metalworking service activities
*26 Manufacture of electronic components and boards
Manufacture of computers and peripheral equipment
Manufacture of communication equipment
Manufacture of consumer electronics
Manufacture of measuring, testing, navigating and control equipment
Manufacture of watches and clocks
Manufacture of optical instruments and photographic equipment
Manufacture of magnetic and optical media
*27 Manufacture of electric motors, generators, transformers and electricity distribution and
control apparatus
Manufacture of batteries and accumulators
Manufacture of fibre optic cables
Manufacture of other electronic and electric wires and cables
Manufacture of wiring devices
Manufacture of electric lighting equipment
Manufacture of domestic appliances
Manufacture of other electrical equipment
*28 Manufacture of engines and turbines, except aircraft, vehicle and cycle engines
Manufacture of fluid power equipment
Manufacture of other pumps, compressors, taps and valves
Manufacture of bearings, gears, gearing and driving elements
Manufacture of ovens, furnaces and furnace burners
Manufacture of lifting and handling equipment
Manufacture of office machinery and equipment (except computers and peripheral
equipment)
Manufacture of power-driven hand tools
Manufacture of other general-purpose machinery
Manufacture of agricultural and forestry machinery
Manufacture of metal-forming machinery and machine tools
Manufacture of machinery for metallurgy
Manufacture of machinery for mining, quarrying and construction
Manufacture of machinery for food, beverage and tobacco processing
Manufacture of machinery for textile, apparel and leather production
Manufacture of other special-purpose machinery
*29 Manufacture of motor vehicles
Manufacture of bodies (coachwork) for motor vehicles; manufacture of trailers and semitrailers
Manufacture of parts and accessories for motor vehicles
*30 Building of ships and floating structures
Building of pleasure and sporting boats
Manufacture of air and spacecraft and related machinery
Manufacture of military fighting vehicles
Manufacture of motorcycles
Manufacture of bicycles and invalid carriages
Manufacture of other transport equipment n.e.c.
*31 Manufacture of furniture
*32 Manufacture of jewellery and related articles
Manufacture of imitation jewellery and related articles
Manufacture of musical instruments
Manufacture of sports goods
Manufacture of games and toys
Manufacture of medical and dental instruments and supplies
*33 Repair of fabricated metal products
Repair of machinery
Repair of electronic and optical equipment
Repair of electrical equipment
Repair of transport equipment, except motor vehicles
Repair of other equipment
Installation of industrial machinery and equipment
*/
*-->
*C 10–33 Manufacturing
gen mainjob_ind_c = (mainjob_activities_code>9.5 & mainjob_activities_code<33.5)

*A.1.D. ELECTRICITY AND GAS
*35 Electricity, gas, steam and air conditioning supply
*-->
*D 35 Electricity, gas, steam and air conditioning supply
gen mainjob_ind_d = (mainjob_activities_code == 35)

*A.1.E. WATER
/*
36 Water collection, treatment and supply
37 Sewerage
38 Waste collection, treatment and disposal activities; materials recovery
39 Remediation activities and other waste management services
*/
*-->
*E 36–39 Water supply; sewerage, waste management and remediation activities
gen mainjob_ind_e = (mainjob_activities_code>35.5 & mainjob_activities_code<39.5)

*A.1.F. CONSTRUCTION
*41 Construction of buildings
*42 Civil engineering
*43 Specialized construction activities (Demolition, Site preparation, Electrical, plumbing and other construction installation activities)
*-->
*F 41–43 Construction
gen mainjob_ind_f = (mainjob_activities_code>40.5 & mainjob_activities_code<43.5)

*A.1.G. WHOLESALE AND RETAIL TRADE AND REPAIR OF MOTOR VEHICLES AND MOTORCYCLES
/*
*45 Wholesale and retail trade and repair of motor vehicles and motorcycles
*46 Wholesale on a fee or contract basis
Wholesale of agricultural raw materials and live animals
Wholesale of food, beverages and tobacco
Wholesale of household goods
Wholesale of machinery, equipment and supplies
Wholesale of solid, liquid and gaseous fuels and related products
Wholesale of metals and metal ores
Wholesale of construction materials, hardware, plumbing and heating equipment and
supplies
Wholesale of waste and scrap and other products n.e.c.
*47 Retail trade, except of motor vehicles and motorcycles
*/
*-->
*G 45–47 Wholesale and retail trade; repair of motor vehicles and motorcycles
gen mainjob_ind_g = (mainjob_activities_code>44.5 & mainjob_activities_code<47.5)

*A.1.H. TRANSPORTATION AND STORAGE
/*
*49 Land transport and transport via pipelines
*50 Water transport
*51 Air transport
*52 Warehousing, storage and support activities for transportation
*53 Postal and courier activities
*/
*-->
*H 49–53 Transportation and storage
gen mainjob_ind_h = (mainjob_activities_code>48.5 & mainjob_activities_code<53.5)

*A.1.I. ACCOMMODATION AND FOOD SERVICE ACTIVITIES
/*
*55 Accommodation
*56 Food and beverage service activities
*/
*-->
*I 55–56 Accommodation and food service activities
gen mainjob_ind_i = (mainjob_activities_code>54.5 & mainjob_activities_code<56.5)

*A.1.J. INFORMATION AND COMMUNICATION
*58 Publishing activities
*59 Motion picture, video and television programme production, 
*sound recording and music publishing activities
*60 Programming and broadcasting activities
*61 Telecommunications
*62 Computer programming, consultancy and related activities
*63 Information service activities
*/
*-->
*J 58–63 Information and communication
gen mainjob_ind_j = (mainjob_activities_code>57.5 & mainjob_activities_code<63.5)

*A.1.K. FINANCIAL AND INSURANCE ACTIVITIES
/*
*64 Financial service activities, except insurance and pension funding
*65 Insurance, reinsurance and pension funding, except compulsory social security
*66 Activities auxiliary to financial service and insurance activities
*/
*-->
*K 64–66 Financial and insurance activities
gen mainjob_ind_k = (mainjob_activities_code>63.5 & mainjob_activities_code<66.5)

*A.1.L. REAL ESTATE ACTIVITIES
*68 Real estate activities with own or leased property
*Real estate activities on a fee or contract basis
*-->
*L 68 Real estate activities
gen mainjob_ind_l = (mainjob_activities_code == 68) 

*A.1.M. PROFESSIONAL, SCIENTIFIC AND TECHNICAL ACTIVITIES
/*
*69 Legal and accounting activities
*70 Activities of head offices; management consultancy activities
*71 Architectural and engineering activities; technical testing and analysis
*72 Scientific research and development
*73 Advertising and market research
*74 Other professional, scientific and technical activities
*75 Veterinary activities
*/
*-->
*M 69–75 Professional, scientific and technical activities
gen mainjob_ind_m = (mainjob_activities_code<68.5 & mainjob_activities_code<75.5)

*A.1.N. ADMINISTRATIVE AND SUPPORT SERVICE ACTIVITIES
/*
*77 Rental and leasing activities
*78 Employment activities
*79 Travel agency, tour operator, reservation service and related activities
*80 Security and investigation activities
*81 Services to buildings and landscape activities
*82 Office administrative, office support and other business support activities
*/
*-->
*N 77–82 Administrative and support service activities
gen mainjob_ind_n = (mainjob_activities_code>76.5 & mainjob_activities_code<82.5)

*A.1.O. PUBLIC ADMINISTRATION AND DEFENCE; COMPULSORY SOCIAL SECURITY
*84 Administration of the State and the economic and social policy of the community
*Provision of services to the community as a whole
*-->
*O 84 Public administration and defence; compulsory social security
gen mainjob_ind_o = (mainjob_activities_code == 84)

*A.1.P. EDUCATION
/*
*85 Pre-primary and primary education
Secondary education
Higher education
Other education (Sports and recreation education, Cultural education)
Educational support activities
*/
*-->
*P 85 Education
gen mainjob_ind_p = (mainjob_activities_code == 85)

*A.1.Q.HUMAN HEALTH AND SOCIAL WORK ACTIVITIES
*86 Human health activities
*87 Residential care activities
*88 Social work activities without accommodation
*-->
*Q 86–88 Human health and social work activities
gen mainjob_ind_q = (mainjob_activities_code>85.5 & mainjob_activities_code<88.5)

*A.1.R. ARTS, ENTERTAINMENT AND RECREATION
/*
*90 Creative, arts and entertainment activities
*91 Libraries, archives, museums and other cultural activities
*92 Gambling and betting activities
*93 Sports activities and amusement and recreation activities
*/
*-->
*R 90–93 Arts, entertainment and recreation
gen mainjob_ind_r = (mainjob_activities_code>89.5 & mainjob_activities_code<93.5)

*A.1.S. OTHER SERVICE ACTIVITIES
/*
*94 Activities of membership organizations
*95 Repair of computers and personal and household goods
*96 Other personal service activities (Washing and (dry-) cleaning of textile and fur products,
Hairdressing and other beauty treatment, Funeral and related activities)
*/
*-->
*S 94–96 Other service activities
gen mainjob_ind_s = (mainjob_activities_code>93.5 & mainjob_activities_code<96.5)

*A.1.T. ACTIVITIES OF HOUSEHOLDS AS EMPLOYERS; UNDIFFERENTIATED GOODS- AND
*SERVICES-PRODUCING ACTIVITIES OF HOUSEHOLDS FOR OWN USE
*97 Activities of households as employers of domestic personnel
*98 Undifferentiated goods- and services-producing activities of private households for own use
*-->
*T 97–98 Activities of households as employers; 
*undifferentiated goods- and services-producing activities of households for own use
gen mainjob_ind_t = (mainjob_activities_code>96.5 & mainjob_activities_code<98.5)

*A.1.U. ACTIVITIES OF EXTRATERRITORIAL ORGANIZATIONS AND BODIES, AND
*ACTIVITIES NOT ADEQUATELY DEFINED
*99 Activities of extraterritorial organizations and bodies
*00 ACTIVITIES NOT ADEQUATELY DEFINED
*-->
*U 99 Activities of extraterritorial organizations and bodies
gen mainjob_ind_u = (mainjob_activities_code == 99 | mainjob_activities_code==0)


*********************************************************
*Avoid wrong coding due to missing data in the original variables 
foreach var of varlis mainjob_ind_* {
replace `var'=. if mainjob_activities_code == .
}
*********************************************************
gen mainjob_all_industries= mainjob_ind_a*1 + mainjob_ind_b*2 + mainjob_ind_c*3 + ///
mainjob_ind_d*4 + mainjob_ind_e*5 + mainjob_ind_f*6 + mainjob_ind_g*7 + ///
mainjob_ind_h*8 + mainjob_ind_i*9 + mainjob_ind_j*10 + mainjob_ind_k*11 + ///
mainjob_ind_l*12 + mainjob_ind_m*13 + mainjob_ind_n*14 + mainjob_ind_o*15 + ///
mainjob_ind_p*16 + mainjob_ind_q*17
 
***A.2 INDIVIDUAL MAIN JOB - OCCUPATION CODES 
/*
*10 categories for occupation codes according to LSMS_ISA for 
*"this specific dataset (IHS4)" (Malawi in 2019~2020)
*@https://microdata.worldbank.org/index.php/catalog/2936/download/47116, page #36
*Header structure: (Code Description)
*/

/*
to be revised:
MAJOR GROUP 0: NEITHER ADEQUATELY DESCRIBED NOR CLASSIFIED LABOURERES
*99 Labourers not elsewhere classified. Workers not reporting occupation, 
*or occupation not adequately describe or not classified.
(Not ganyu labourersganyu work covered in separate questions.)
*/
gen mainjob_occ_0 = (mainjob_occupations_code<1 | mainjob_occupations_code==99)
label variable mainjob_occ_0 "Neither adequately described nor classified laboureres"

/*
MAJOR GROUP 0/1: PROFESSIONAL, TECHNICAL, & RELATED WORKERS
------
*01 Physical Scientists and related technicians. Chemists, Physicists
*02 Architects, Surveyors and related workers. Architects, Planners, Surveyors,
Draughtsmen and related workers
*03 Engineers and related workers. Civil, Mechanical, Electrical, Mining and
Other Engineers; Mining Technicians
*04 Aircraft's and ships' officers. Pilots, Navigators, deck officers, flight and
ships‟ officers
*05 Life scientists and related technicians. Agronomists, biologists, zoologists.
*06 Medical, dental and related workers. Doctors, Dentists, Medical and Dental
Assistants, Nurses, X-ray and other medical technicians. (Excluding
traditional healers (which are group 59))
*07 Veterinary and related workers. Veterinarians and related workers not
elsewhere classified
*08 Statisticians, mathematicians, systems analysts. Statisticians, actuaries,
systems analysts and related technicians
*09 Economists
*11 Accountants, (private or government); (for book-keepers see 33)
*12 Jurists. Lawyers, Judges
*13 Teachers. University Lectures and teachers.
*14 Workers in Religion. Priests, nuns lay brothers etc, and related workers in
religion not elsewhere classified
*15 Writers. Authors, journalists, critics and related writers.
16 Artists. Sculptors, painters of pictures, photographers and cameramen.
*17 Composers and Performing artists. Composers, musicians, singers, dancers,
actors, producers, performing artists.
*18 Athletics, sportsmen and related workers. Athletes, etc.
*19 Professional and technical workers not elsewhere classified. Librarians,
archivists, curators, sociologists, social workers and occupational specialists,
translators, interpreter
*/
gen mainjob_occ_1 = (mainjob_occupations_code>0 & mainjob_occupations_code<20)
label variable mainjob_occ_1 "Occupation group: Professional, Technical, & Related Workers"

/*
MAJOR GROUP 2: ADMINISTRATION AND MANAGERIAL WORKERS
-------
*20 Legislative Officials and government senior administrators. Legislative
officials.
*21 Managers. General Managers, production managers (except farm managers)
and managers not elsewhere classified.
*22 Traditional Leaders. Village Headmen, Group Village Headmen, SubTraditional Authorities, Traditional Authorities, Senior Traditional
Authorities/Chiefs, Paramount Chiefs.
*/
gen mainjob_occ_2 = (mainjob_occupations_code>19 & mainjob_occupations_code<30)
label variable mainjob_occ_2 "Occupation group: Administration And Managerial Workers"

/*
MAJOR GROUP 3: CLERICAL AND RELATED WORKER
------
*30 Clerical supervisors
*31 Government administrative/secretarial officials
*32 Stenographers and related workers. Stenographers, typists, card and tape
punching machine operators.
*33 Book-keepers, cashiers and related workers. Book-keepers and cashiers.
*34 Computing and machine operators of book-keeping machines, calculators
and automatic data processing machines (computers).
*35 Transport and communication supervisors. Railway Stations Masters,
postmasters, communication supervisors not elsewhere classified stated.
*36 Transport conductors. Bus conductors
*37 Mail distribution clerks. Registry clerks
*38 Telephone and telegram operators Including switchboard (PBX) operators.
*39 Clerical and related workers not elsewhere classified. Stock Clerk
Correspondence clerks, receptionists, and travel agency clerks, Library and
filling clerks and other clerks and not elsewhere classified.
*/
gen mainjob_occ_3 = (mainjob_occupations_code>29 & mainjob_occupations_code<40)
label variable mainjob_occ_3 "Occupation group: Clerical And Related Worker"

/*
MAJOR GROUP 4: SALES WORKERS
-------
*40 Managers (wholesale & retail trade)
*41 Working proprietors (wholesale and retail trade)
*42 Sales supervisors and buyers
*43 Technical salesmen, commercial travellers, manufactures agency
*44 Auctioneers and salesmen of insurance, real estate, securities, and business
services.
*45 Salesmen and shop assistants, and related workers (demonstrators, street
vendors, canvassers, news vendors).
*49 Sales workers not elsewhere classified.
*/
gen mainjob_occ_4 = (mainjob_occupations_code>39 & mainjob_occupations_code<50)
label variable mainjob_occ_4 "Occupation group: Sales Workers"

/*
MAJOR GROUP 5: SERVICE WORKERS
-------
*50 Managers (catering &lodging services)
*51 Working proprietors (catering & lodging services)
*52 Housekeeping and related service supervisors (Excluding housewives)
*53 Cooks, waiters, bartenders and related workers
*54 Maids and related housekeeping service workers not elsewhere classified,
house girls, houseboys, garden boys
*55 Buildings caretakers, watch guards, charworkers, cleaners and related
workers.
*56 Launderers, dry-cleaners and pressers.
*57 Hairdressers, barbers, beauticians and related workers.
*58 Protective service workers. Fire fighters, policemen and detectives, protective
workers not elsewhere classified.
*59 Service workers not elsewhere classified. Traditional healers, guides,
undertakers and embalmers, other service workers.
*/
gen mainjob_occ_5 = (mainjob_occupations_code>49 & mainjob_occupations_code<60)
label variable mainjob_occ_5 "Occupation group: Service Workers"

/*
MAJOR GROUP 6: AGRICULTURAL, ANIMAL HUSBANDRY AND FORESTRY 
WORKERS, FISHERMEN AND HUNTERS
-------
*60 Farm managers and supervisors
*61 Farmers (general farm owner/operators and specialised farmers)
*62 Agricultural and animal husbandry workers. General farm workers and
labourers, dairy farm workers and gardeners, farm machine operators,
agricultural and animal husbandry workers not elsewhere classified. (Not ganyu
farm labourers-ganyu work covered in separate questions)
*63 Forestry workers. Loggers and other forestry workers not elsewhere classified.
*64 Fishermen, hunters and related workers.
*/
gen mainjob_occ_6 = (mainjob_occupations_code>59 & mainjob_occupations_code<70)
label variable mainjob_occ_6 "Occupation group: Agricultural, Animal Husbandry And Forestry Workers, Fishermen And Hunters"

/*to be revised:
MAJOR GROUP 7/8/9: PRODUCTION AND RELATED WORKERS, TRANSPORT
EQUIPMENT OPERATORS AND LABOURERES NOT ELSEWHERE CLASSIFIED
--------------
to be revised:
MAJOR GROUP 7: PRODUCTION AND RELATED WORKERS
*70 General foreman and production supervisors.
*71 Miners, Quarrymen, well drillers including mineral and stone treaters, well
borers and related workers.
*72 Metal processors, Including melters and reheaters, casters, moulders and
coremakers. Annealers, platers and coaters.
*73 Wood preparation and workers and paper makers. Wood treaters, sawyers,
makers and related wood processing and related workers, paper pulp prepares
and paper makers related workers.
*74 Chemical processors and related workers. Crushers, grinders, mixers, heat
treaters, filter and separator operators, still operators, chemical processors and
related workers not elsewhere classified.
*75 Spinners, weavers, dyers, fibre preparers. Spinners, Weaving and Knitting,
Machine setters and operators bleachers dyers and textile product finishers;
related workers not elsewhere classified.
*76 Tanners, skin preparers and pelt dressers.
*77 Food and beverage processors. Grain millers, sugar processors and refiners,
butchers and daily product processors, bakers tea and coffee prepares, brewers,
beverages makers and other food and beverage processors.
*78 Tobacco preparers and product makers. Tobacco preparers, cigarette makers
and tobacco preparers and tobacco product workers not elsewhere classified.
*79 Tailors, dressmakers, sewers, upholsters. Tailors dressmakers for tailors, hat
makers, cutters, sewers, upholsters and related workers not elsewhere classified.
*80 Shoemakers and leather goods makers. Shoemaker repairers, shoe cutters,
lasters, sewers and related workers; leather goods makers.
*81 Cabinet makers and related wood workers. Cabinet makers, wood-working
machine operators not elsewhere classified.
*82 Stone cutters and carvers.
*83 Blacksmith, toolmakers & machine tool operators. Blacksmith, operators, forgepress operators, toolmakers, machine tool setters & operators, metal grinders,
polishers, sharpeners.
*84 Machinery fitters, machine assemblers. Machinery fitters and assemblers, clock
makers, motor and precision instrument makers, vehicle machine and aircraft
engine mechanics (except electrical)
*85 Electrical fitters and related electrical workers. Electrical fitters wiremen and
linesmen, electrical and electronics workers, electronic equipment assemblers,
radio repairmen telephone and telegram installers and related workers not
elsewhere classified.
*86 Broadcasting station operators and cinema projectionists.
*87 Plumbers, welders, sheet metal workers. Plumbers and pipe fitters, and frame
cutters, sheet structural metal prepares, metal workers, structural metal prepares
and erectors.
*88 Jewellery and precious metal workers.
*89 Potters, glass formers and related workers. Potters, glass formers and cutters
ceramic kinsmen, grass engravers ceramic and glass painters and decorators and
related workers not elsewhere classified
*90 Rubber and plastic product makers. Rubber and plastic product makers not
elsewhere classified (not footwear), tyre makers, vulcanisers and retreaders.
*91 Paper and paper-board product makers.
*92 Printers and related workers. Compositors, typesetters, printing pressmen,
printing and photo engravers book binders, photographic darkroom operators
and related workers not elsewhere classified.
*93 Painters. House painters and the like (not artists).
*94 Production and related workers. Musical instrument makers and tuners,
basketry weavers not elsewhere classified and brush makers, other production
related workers.
*95 Bricklayers, carpenters and other bricklayers. stonemasons, tile setters,
reinforced construction workers concetors, roofers, carpenters and joiners,
plaster, glaziers and construction workers not elsewhere classified. (Not ganyu
labourers - ganyu work covered in separate questions.)
*/
gen mainjob_occ_7 = (mainjob_occupations_code>69 & mainjob_occupations_code<96)
label variable mainjob_occ_7 "Occupation group: Production And Related Workers (7)"

/*to be revised:
*MAJOR GROUP 8: PRODUCTION AND RELATED WORKERS
*96 Operators of stationery engines and power generating machines. Operators
and operators of related equipment other stationery engines (i.e. not vehicles
tractors etc) and related equipment not elsewhere classified.
*97 Material handling and related equipment operators. Dockers and handlers,
riggers, crane and hoist operators, Dockers and freight handlers/operators, earth
moving and related machinery operators and material-handling equipment
operators not elsewhere classified.
*/
gen mainjob_occ_8 = (mainjob_occupations_code>95 & mainjob_occupations_code<98)
label variable mainjob_occ_8 "Occupation group: Production And Related Workers (8)"

/*to be revised:
*MAJOR GROUP 9: TRANSPORT EQUIPMENT OPERATORS
*98 Transport equipment operators. Vehicles drivers, railway engine drivers and
firemen, ships rating crew, railway breakmen shunters, signalmen and transport
equipment operators not elsewhere classified.
*/
gen mainjob_occ_9 = (mainjob_occupations_code==98)
label variable mainjob_occ_9 "Occupation group: Transport Equipment Operators"

foreach var of varlis mainjob_occ_* {
replace `var'=. if mainjob_occupations_code == .
}

gen mainjob_all_occupations = mainjob_occ_0*0 + mainjob_occ_1*1 + mainjob_occ_2*2 + ///
mainjob_occ_3*3 + mainjob_occ_4*4 + mainjob_occ_5*5 + mainjob_occ_6*6 + ///
mainjob_occ_7*7 + mainjob_occ_8*8 + mainjob_occ_9*9

//convert some numeric variables in string type to numbers for later appendage of 2011, 2016, and 2019 datasets
destring hh_e59_1a, replace
destring hh_e59_1b, replace

***A.3 INDIVIDUAL MAIN JOB - WAGES/SALARY INCOME
*Job sector
/*
The possible values for hh_e21 according to the Household questionaire:
Private Company........1
Private Individual.....2
Government.............3
State-Owned Enterprise
(Parastatal)...........4
MASAF/Public Works
Program................5
Church/Religious
Organization...........6
Political Party........7
Other (Specify)........8
*/
rename hh_e21 mainjob_sector
gen mainjob_sector_public = (mainjob_sector>2 & mainjob_sector<8)
replace mainjob_sector_public = . if mainjob_sector == .
gen mainjob_sector_gen_gov = mainjob_ind_l + mainjob_ind_m + mainjob_ind_n
replace mainjob_sector_gen_gov = 0 if mainjob_sector_public == 0

*Worked time over the last 12 months
//number of months the individual worked (during the period)
rename hh_e22 mainjob_worked_months

//number of weeks per month the individual worked (during the period)
rename hh_e23 mainjob_worked_weeks_pmonth

//number of hours per week the individual worked (during the period)
rename hh_e24 mainjob_worked_hours_pweek

gen mainjob_worked_hours_pmonth = mainjob_worked_hours_pweek*mainjob_worked_weeks_pmonth

//the last wages/salary received for time units of working (main job)
rename hh_e25 mainjob_wagessalary_last

/*
Time units (hh_e26b)
-----
DAY 3
WEEK 4
MONTH 5
*/

gen mainjob_income_wagessalary = .
label variable mainjob_income_wagessalary "annual income from wages/salary (over the last 12 months: 2019~2020)(main job)"

//hh_e26a: number of time units corresponding to the last payment received
rename hh_e26a mainjob_numberof_timeunits
//(hh_e26b)time unit: month 
replace mainjob_income_wagessalary = (mainjob_wagessalary_last/mainjob_numberof_timeunits)*mainjob_worked_months if hh_e26b == 5 

//(hh_e26b)time unit: week 
replace mainjob_income_wagessalary = (mainjob_wagessalary_last/mainjob_numberof_timeunits)*(mainjob_worked_weeks_pmonth*mainjob_worked_months) if hh_e26b == 4

//(hh_e26b)time unit: day
//presume common work hours per day is 8 hours (refer to Malawi Employment Act 2000,
//Section #36 and #37 in Part VI - Hours of Work, Weekly Rest and Leave,
//@https://www.ilo.org/dyn/natlex/docs/ELECTRONIC/58791/97712/F992720056/MWI58791.pdf)
replace mainjob_income_wagessalary = (mainjob_wagessalary_last/mainjob_numberof_timeunits/8)*(mainjob_worked_hours_pweek*mainjob_worked_weeks_pmonth*mainjob_worked_months) if hh_e26b == 3


***A.4 INDIVIDUAL MAIN JOB - IN-KIND INCOME
/*
The same calculation methodology for the in-kind payments
In-kind payments: allowances or gratuities such as
uniform, housing, food, and transport, that were not included in the wages/salary 
the individual just reported
*/
//the usual in-kind payments received for time units of working (main job)
rename hh_e27 mainjob_usualpayment_inkind

gen mainjob_income_inkind = .
label variable mainjob_income_inkind "annual income from in-kind payments (over the last 12 months: 2019~2020)(main job)"

//hh_e28a: the number of time units corresponding to the the allowances or gratuities received
rename hh_e28a mainjob_inkind_numberoftimeunits
//time unit: day
replace mainjob_income_inkind = (mainjob_usualpayment_inkind/mainjob_inkind_numberoftimeunits/8)*(mainjob_worked_hours_pweek*mainjob_worked_weeks_pmonth*mainjob_worked_months) if hh_e28b == 3

//time unit: week
replace mainjob_income_inkind = (mainjob_usualpayment_inkind/mainjob_inkind_numberoftimeunits)*(mainjob_worked_weeks_pmonth*mainjob_worked_months) if hh_e28b == 4 

//time unit: month
replace mainjob_income_inkind = (mainjob_usualpayment_inkind/mainjob_inkind_numberoftimeunits)*mainjob_worked_months if hh_e28b == 5

//Cost for this job if it is an apprenticeship and the individual had to paid an amount for it 
gen mainjob_cost_apprenticeship = (-1)*hh_e31 if hh_e29 == 1 & hh_e30 == 1

////Annual (2019~2020) total income from the main job (sum of regular wages/salary and in-kind payments)
egen mainjob_income = rowtotal(mainjob_income_wagessalary mainjob_income_inkind mainjob_cost_apprenticeship)
replace mainjob_income = . if mainjob_income == 0
label variable mainjob_income "Annual total income (main job) (2019~2020)"


****************B. INDIVIDUAL INCOME - SECOND JOB**************************

***B.1 INDIVIDUAL SECONDARY JOB - WAGES/SALARY INCOME
*Worked time over the last 12 months
//number of months over the last 12 months (2019~2020) the individual worked (secondary job)
rename hh_e36 secondjob_worked_months

//number of weeks per month the individual worked (secondary job)
rename hh_e37 secondjob_worked_weeks_pmonth

//number of hours per week the individual worked (secondary job)
rename hh_e38 secondjob_worked_hours_pweek

gen secondjob_worked_hours_pmonth = secondjob_worked_hours_pweek*secondjob_worked_weeks_pmonth
label variable secondjob_worked_hours_pmonth "number of hours per month the individual worked (secondary job)"

//the last wages/salary received for time units of working (secondary job)
rename hh_e39 secondjob_wagessalary_last

/*
Time units (hh_e40b)
//DAY 3 //there is no observation for "day" time units
WEEK 4
MONTH 5
*/

gen secondjob_income_wagessalary = .
label variable secondjob_income_wagessalary "annual income from wages/salary (over the last 12 months: 2019~2020) (secondary job)"

//hh_e40a: number of time units corresponding to the last payment received
//(hh_e40b)time unit: month 
destring hh_e40a, replace //convert numeric strings to numbers
rename hh_e40a secondjob_numberof_timeunits
replace secondjob_income_wagessalary = (secondjob_wagessalary_last/secondjob_numberof_timeunits)*secondjob_worked_months if hh_e40b == 5

//time unit: week 
replace secondjob_income_wagessalary = (secondjob_wagessalary_last/secondjob_numberof_timeunits)*(secondjob_worked_weeks_pmonth*secondjob_worked_months) if hh_e40b == 4

//(hh_e40b)time unit: day
//presume common work hours per day is 8 hours (refer to Malawi Employment Act 2000,
//Section #36 and #37 in Part VI - Hours of Work, Weekly Rest and Leave,
//@https://www.ilo.org/dyn/natlex/docs/ELECTRONIC/58791/97712/F992720056/MWI58791.pdf)
//There is no observation for "day" time units
//replace secondjob_income_wagessalary = (secondjob_wagessalary_last/secondjob_numberof_timeunits/8)*(secondjob_worked_hours_pweek*secondjob_worked_weeks_pmonth*secondjob_worked_months) if hh_e40b == 3

***B.2 INDIVIDUAL SECONDARY JOB - IN-KIND INCOME
/*
The same calculation methodology for the in-kind payments
In-kind payments: allowances or gratuities such as
uniform, housing, food, and transport, that were not included in the salary 
the individual just reported
*/
destring hh_e41, replace //convert numeric strings to numbers
//the usual in-kind payments received for time units of working (secondary job)
rename hh_e41 secondjob_usualpayment_inkind 

gen secondjob_income_inkind = .
label variable secondjob_income_inkind "annual income from in-kind payments (over the last 12 months: 2019~2020)(secondary job)"

//hh_e42a: the number of time units corresponding to the the allowances or gratuities received
rename hh_e42a secondjob_inkind_nmbroftimeunits
//(hh_e42b)time unit: day
replace secondjob_income_inkind = (secondjob_usualpayment_inkind/secondjob_inkind_nmbroftimeunits/8)*(secondjob_worked_hours_pweek*secondjob_worked_weeks_pmonth*secondjob_worked_months) if hh_e42b == 3

//(hh_e42b)time unit: week
replace secondjob_income_inkind = (secondjob_usualpayment_inkind/secondjob_inkind_nmbroftimeunits)*(secondjob_worked_weeks_pmonth*secondjob_worked_months) if hh_e42b == 4 

//(hh_e42b)time unit: month
replace secondjob_income_inkind = (secondjob_usualpayment_inkind/secondjob_inkind_nmbroftimeunits)*secondjob_worked_months if hh_e42b == 5

//to be revised:
//Cost for this job if it is an apprenticeship and the individual had to pay an amount for it
gen secondjob_cost_apprenticeship = (-1)*hh_e45 if hh_e43 == 1 & hh_e44 == 1

////Annual (2019~2020) total income from the second job (sum of regular wages/salary and in-kind payments)
egen secondjob_income = rowtotal(secondjob_income_wagessalary secondjob_income_inkind secondjob_cost_apprenticeship)
replace secondjob_income = . if secondjob_income == 0
label variable secondjob_income "Annual total income (2019~2020) (secondary job)"


****************C. INDIVIDUAL UNPAID APPRENTICESHIP************************
*Worked time
gen uapprentship_worked_months = hh_e50
label variable uapprentship_worked_months "number of months over the last 12 months (2019~2020) the individual worked (unpaid apprenticeship)"
gen uapprentship_worked_weeks_pmonth = hh_e51
label variable uapprentship_worked_weeks_pmonth "number of weeks per month the individual worked (unpaid apprenticeship)"
gen uapprentship_worked_hours_pweek = hh_e52
label variable uapprentship_worked_hours_pweek "number of hours per week the individual worked (unpaid apprenticeship)"
gen uapprentship_worked_hours_pmonth = uapprentship_worked_hours_pweek*uapprentship_worked_weeks_pmonth

//Cost for this unpaid apprenticeship
gen uapprentship_cost = hh_e54 if hh_e53 == 1


****************D. INDIVIDUAL INCOME - GANYU LABOUR************************

***D.1 INDIVIDUAL GANYU LABOUR - WAGES INCOME
*Worked time
//number of months over the last 12 months (2019~2020) the individual worked (ganyu labour)
rename hh_e56 ganyu_worked_months

//number of weeks per month the individual worked (ganyu labour)
rename hh_e57 ganyu_worked_weeks_pmonth

//number of days per week the individual worked (ganyu labour)
rename hh_e58 ganyu_worked_days_pweek

//wages received
//h_e59: daily wage in cash or in kind
gen ganyu_income = hh_e59*ganyu_worked_days_pweek*ganyu_worked_weeks_pmonth*ganyu_worked_months
replace ganyu_income = . if ganyu_income == 0
label variable ganyu_income "Annual total income (2019~2020) (ganyu labour)"


*********INDIVIDUAL ANNUAL TOTAL INCOME************
egen individual_alljobswork_income = rowtotal(mainjob_income secondjob_income ganyu_income)
replace individual_alljobswork_income = . if individual_alljobswork_income == 0
label variable individual_alljobswork_income "annual total income (2019~2020) from all jobs/work (individual)"

gen surveyyear = 2019
label variable surveyyear "IHS5: 2019 ~ 2020 (the period of conducting survey)"

order surveyyear hhid_ihs_surveysolutions hhid_ihs_serial pid_seq /// 
location_urban hhsize pweight /// 
demo_sex demo_age demo_marital demo_birthyear demo_birthmonth /// 
demo_school_attended demo_schoolingstartage demo_school_lastattend ///
yearsofschooling education_highest /// 
mainjob_activities_code mainjob_occupations_code mainjob_ind_a - mainjob_ind_u mainjob_all_industries /// 
mainjob_occ_0 - mainjob_occ_9 mainjob_all_occupations ///
mainjob_sector mainjob_sector_public mainjob_sector_gen_gov /// 
mainjob_income_wagessalary mainjob_income_inkind mainjob_income ///
secondjob_income_wagessalary secondjob_income_inkind secondjob_income ///
ganyu_income individual_alljobswork_income

keep surveyyear hhid_ihs_surveysolutions hhid_ihs_serial pid_seq location_urban hhsize pweight /// 
demo_sex demo_age demo_marital demo_birthyear demo_birthmonth /// 
demo_school_attended demo_schoolingstartage demo_school_lastattend ///
yearsofschooling education_highest /// 
mainjob_activities_code mainjob_occupations_code mainjob_ind_a - mainjob_ind_u mainjob_all_industries /// 
mainjob_occ_0 - mainjob_occ_9 mainjob_all_occupations ///
mainjob_sector mainjob_sector_public mainjob_sector_gen_gov /// 
mainjob_income_wagessalary mainjob_income_inkind mainjob_income ///
secondjob_income_wagessalary secondjob_income_inkind secondjob_income ///
ganyu_income individual_alljobswork_income

//save "G:\Onedrive\MicroDataProject\original_data\Malawi\2011\individual_data_income.dta", 
save ".//individual_data_income.dta", replace

//Note: to be revised:
//The total income of a household could be equal to: 
//(the total income of all members) + (its income) 
//Aggregate individual income at household level
collapse (sum) individual_alljobswork_income, by (surveyyear hhid_ihs_serial hhid_ihs_surveysolutions)
rename individual_alljobswork_income household_allindividuals_income
replace household_allindividuals_income = . if household_allindividuals_income == 0
label variable household_allindividuals_income "total annual (2010~2011) income of all individuals at household level"
order surveyyear hhid_ihs_surveysolutions hhid_ihs_serial
save ".//household_income_allindividuals.dta", replace 


****************E. INDIVIDUAL INFORMATION************************
***
**E.1 INDIVIDUAL INFORMATION - DEMOGRAPHICS
//use "C:\Users\ASUS\Downloads\MWI_2010_IHS-III_v01_M_STATA8\MWI_2010_IHS-III_v01_M_STATA8\Full_Sample\Household\hh_mod_b.dta", clear
use ".//hh_mod_b.dta", clear
rename HHID hhid_ihs_surveysolutions
rename case_id hhid_ihs_serial
rename PID pid_seq
rename hh_b03 demo_sex
rename hh_b04 demo_relationship_to_head 
rename hh_b05a demo_age 
rename hh_b22 demo_ethnic //language speak
rename hh_b23 demo_religion 
rename hh_b24 demo_marital
rename hh_b18 demo_fatheredu_highest
rename hh_b21 demo_motheredu_highest
rename hh_b17 demo_fatherdeath_age
rename hh_b20 demo_motherdeath_age

gen surveyyear = 2019
label variable surveyyear "IHS5: 2019 ~ 2020 (the period of conducting survey)"

order surveyyear hhid_ihs_surveysolutions hhid_ihs_serial pid_seq /// 
demo_relationship_to_head demo_sex demo_age demo_ethnic demo_religion demo_marital /// 
demo_fatheredu_highest demo_motheredu_highest /// 
demo_fatherdeath_age demo_motherdeath_age

keep surveyyear hhid_ihs_surveysolutions hhid_ihs_serial pid_seq /// 
demo_relationship_to_head demo_sex demo_age demo_ethnic demo_religion demo_marital /// 
demo_fatheredu_highest demo_motheredu_highest /// 
demo_fatherdeath_age demo_motherdeath_age

//save "G:\Onedrive\MicroDataProject\original_data\Malawi\2011\individual_data_demo.dta", replace 
save ".//individual_data_demo.dta", replace 

**E.2 INDIVIDUAL INFORMATION - EDUCATION
//use "C:\Users\ASUS\Downloads\MWI_2010_IHS-III_v01_M_STATA8\MWI_2010_IHS-III_v01_M_STATA8\Full_Sample\Household\hh_mod_c.dta", clear
use ".//hh_mod_c.dta", clear
rename HHID hhid_ihs_surveysolutions
rename case_id hhid_ihs_serial
rename PID pid_seq
rename hh_c13 education_schooling
rename hh_c09 education_highest

gen surveyyear = 2019
label variable surveyyear "IHS5: 2019 ~ 2020 (the period of conducting survey)"

order surveyyear hhid_ihs_surveysolutions hhid_ihs_serial pid_seq /// 
education_schooling education_highest

keep surveyyear hhid_ihs_surveysolutions hhid_ihs_serial pid_seq /// 
education_schooling education_highest
//save "G:\Onedrive\MicroDataProject\original_data\Malawi\2011\individual_data_educ.dta", replace
save ".//individual_data_educ.dta", replace 

foreach file in individual_data_demo individual_data_income {
merge 1:1 hhid_ihs_serial pid_seq using `file', nogen
}
order surveyyear hhid_ihs_surveysolutions hhid_ihs_serial pid_seq
save ".//individual_data.dta", replace


********************************************************************************
********************************************************************************
****************F. HOUSEHOLD VARIABLES******************************************
********************************************************************************
********************************************************************************
****************INCOME********

*F.1 HOUSEHOLD INCOME FROM non-agricultural self-employed activities (ENTERPRISES OR BUSINESSES)
//use "G:\Onedrive\MicroDataProject\original_data\Malawi\2011\Household_data\HH_MOD_N2.dta", clear
use ".//HH_MOD_N2.dta", clear
merge m:1 HHID using HH_MOD_N1, keepusing(case_id HHID)
keep if _merge == 3 //keep matched observations which are in both datasets
drop _merge
order case_id HHID
rename HHID hhid_ihs_surveysolutions
rename case_id hhid_ihs_serial
/*
SHARE = What share of the profits from this [ENTERPRISE] is kept by your household,
rather than the other owners?
Responses (hh_n14):
Almost none..1
About 25%....2
About half...3
About 75%....4
Almost all...5
Other
(Specify)....6
 SHARE | Freq. Percent Cum.
----------------+-----------------------------------
 Almost none | 12 12.90 12.90
 About 25% | 20 21.51 34.41
 About half | 30 32.26 66.67
 About 75% | 5 5.38 72.04
 Almost all | 26 27.96 100.00
----------------+-----------------------------------
 Total | 93 100.00
*/
rename hh_n40 business_profits
rename hh_n14 profits_share
gen household_income_business = business_profits*profits_share

gen surveyyear = 2019
label variable surveyyear "IHS5: 2019 ~ 2020 (the period of conducting survey)"

order surveyyear hhid_ihs_surveysolutions hhid_ihs_serial /// 
business_profits profits_share household_income_business 

keep surveyyear hhid_ihs_surveysolutions hhid_ihs_serial /// 
business_profits profits_share household_income_business  
//save "G:\Onedrive\MicroDataProject\original_data\Malawi\2011\non_ag_self_income.dta", replace 
save ".//household_income_non_ag_self.dta", replace 

//A household could operate or own two or more enterprises or businesses
//The total income from all businesses are aggregated for each household.
collapse (sum) household_income_business, by(surveyyear hhid_ihs_serial hhid_ihs_surveysolutions)
rename household_income_business household_income_businesses
label variable household_income_businesses "household annual income (2019~2020) from operating enterprises or businesses" 
replace household_income_businesses = . if household_income_businesses == 0
order surveyyear hhid_ihs_surveysolutions hhid_ihs_serial
save ".//household_income_total_non_ag_self.dta", replace 


*F.2 HOUSEHOLD INCOME FROM REMITTANCES (BY CHILDREN LIVING ELSEWHERE)**
//use "G:\Onedrive\MicroDataProject\original_data\Malawi\2011\Household_data\HH_MOD_O.dta", clear 
use ".//HH_MOD_O.dta", clear 
rename HHID hhid_ihs_surveysolutions
rename case_id hhid_ihs_serial
//the amount in cash as a remittance received monthly
rename hh_o13 household_income_remittmonthly

//the amount in cash as a remittance received from one child annually (2019~2020)
rename hh_o14 household_income_remittannual

//the estimated cash value as in-kind assistance received from one child annually (2019~2020)
rename hh_o17 household_income_remitinkindyrly

egen household_income_remittance = rowtotal(household_income_remittannual household_income_remitinkindyrly) 
replace household_income_remittance = . if household_income_remittance == 0
label variable household_income_remittance "annual remittance income (2019~2020) from one child living elsewhere"

gen surveyyear = 2019
label variable surveyyear "IHS5: 2019 ~ 2020 (the period of conducting survey)"

order surveyyear hhid_ihs_surveysolutions hhid_ihs_serial /// 
household_income_remittmonthly household_income_remittannual /// 
household_income_remitinkindyrly household_income_remittance

keep surveyyear hhid_ihs_surveysolutions hhid_ihs_serial /// 
household_income_remittmonthly household_income_remittannual /// 
household_income_remitinkindyrly household_income_remittance
//save "G:\Onedrive\MicroDataProject\original_data\Malawi\2011\remitance_income.dta", replace
save ".//household_income_remittance.dta", replace 

//The head or spouse of a household could have a number of children living elsewhere who send cash and in-kind assistances (estimated cash values) to their household.
//The total remittance is needed for each household. 
collapse (sum) household_income_remittance, by(surveyyear hhid_ihs_serial hhid_ihs_surveysolutions)
rename household_income_remittance household_income_remittances
label variable household_income_remittances "annual remittance income (2019~2020) from all children living elsewhere" 
replace household_income_remittances = . if household_income_remittances == 0
order surveyyear hhid_ihs_surveysolutions hhid_ihs_serial
save ".//household_income_total_remittance.dta", replace 

//to be revised:
//Note: for now, the housing income is not included into the income aggregation.
//For later analyses, the housing income may be useful.
*F.3 HOUSEHOLD ESTIMATED INCOME FROM HOUSING (SELLING DWELLING AND RENT)**
use HH_MOD_F, clear
rename HHID hhid_ihs_surveysolutions
rename case_id hhid_ihs_serial
gen house_ownership = hh_f01
gen income_housevalue_estimate = hh_f02
gen income_rent_annual_estimate = hh_f03a if hh_f03a == 6 //yearly
replace income_rent_annual_estimate = hh_f03a*12 if hh_f03a == 5 //monthly
replace income_rent_annual_estimate = hh_f03a*4*12 if hh_f03a == 4 //weekly
replace income_rent_annual_estimate = hh_f03a*365 if hh_f03a == 3 //daily
egen income_housing = rowtotal(income_housevalue_estimate income_rent_annual_estimate) 
replace income_housing = . if income_housing == 0

gen surveyyear = 2019
label variable surveyyear "IHS5: 2019 ~ 2020 (the period of conducting survey)"

keep surveyyear hhid_ihs_surveysolutions hhid_ihs_serial income_housevalue_estimate income_rent_annual_estimate income_housing
//save "G:\Onedrive\MicroDataProject\original_data\Malawi\2011\household_income_housing.dta", replace
order surveyyear hhid_ihs_surveysolutions hhid_ihs_serial
save ".//household_income_housing.dta", replace 


*F.4 HOUSEHOLD OTHER INCOME****
//use "G:\Onedrive\MicroDataProject\original_data\Malawi\2011\Household_data\HH_MOD_P.dta", clear
use ".//HH_MOD_P.dta", clear 
rename HHID hhid_ihs_surveysolutions
rename case_id hhid_ihs_serial
//annual income from various sources other than businesses and remittances
rename hh_p02 household_income_other

gen surveyyear = 2019
label variable surveyyear "IHS5: 2019 ~ 2020 (the period of conducting survey)"

keep surveyyear hhid_ihs_surveysolutions hhid_ihs_serial household_income_other 
//save "G:\Onedrive\MicroDataProject\original_data\Malawi\2011\other_income.dta", replace 
order surveyyear hhid_ihs_surveysolutions hhid_ihs_serial
save ".//household_income_other.dta", replace 

//A household could have other income from various sources.
//The aggregation of other income is necessary. 
collapse (sum) household_income_other, by(surveyyear hhid_ihs_serial hhid_ihs_surveysolutions)
rename household_income_other household_income_others
label variable household_income_others "annual income (2019~2020) from various sources other than businesses and remittances"
replace household_income_others = . if household_income_others == 0
order surveyyear hhid_ihs_surveysolutions hhid_ihs_serial
save ".//household_income_total_other.dta", replace 


*******MERGING THE GENERATED HOUSEHOLD INCOME DATASETS****
use ".//household_income_total_non_ag_self.dta", clear 
foreach file in household_income_total_remittance household_income_housing household_income_total_other {
merge 1:1 hhid_ihs_serial using `file', nogen
}
egen household_income_total = rowtotal(household_income_businesses household_income_remittances household_income_others)
label variable household_income_total "annual total income (2019~2020) from businesses, remittances, and other income"
replace household_income_total = . if household_income_total == 0
save ".//household_income_total_alone.dta", replace 

//to be revised
use ".//household_income_allindividuals.dta", clear
merge 1:1 hhid_ihs_serial using household_income_total_alone, nogen
egen household_income_aggregate = rowtotal(household_income_total household_allindividuals_income)
label variable household_income_aggregate "annual household aggregate income (2010~2011) from its own income and all of its members"
replace household_income_aggregate = . if household_income_aggregate == 0
save ".//household_income_aggregate_with_individuals.dta", replace 


****************HOUSEHOLD EXPENDITURE********
*provided by the data creator in ihs3fc2M_consumption.dta 

****************G. MERGING HOUSEHOLD INCOME & EXPENDITURE********
//use "G:\Onedrive\MicroDataProject\original_data\Malawi\2011\Household_data\ihs3fc2M_consumption.dta", clear
use "ihs5_consumption_aggregate.dta", clear
rename HHID hhid_ihs_surveysolutions
rename case_id hhid_ihs_serial
merge 1:1 hhid_ihs_serial using household_income_aggregate_with_individuals, nogen

//calculate real income using the built-in Spatial and Temporal Price Index for each household (Base National Feb/Mar 2010)
//append the prefix "real" to the nominal income variables
local reallab = "real "

gen rhousehold_allindividuals_income = household_allindividuals_income/price_indexL*100
local tmplab: variable label household_allindividuals_income
local tmplab = "`reallab'" + "`tmplab'"
label variable rhousehold_allindividuals_income "`tmplab'"

gen rhousehold_income_businesses = household_income_businesses/price_indexL*100
local tmplab: variable label household_income_businesses
local tmplab = "`reallab'" + "`tmplab'"
label variable rhousehold_income_businesses "`tmplab'"

gen rhousehold_income_remittances = household_income_remittances/price_indexL*100
local tmplab: variable label household_income_remittances
local tmplab = "`reallab'" + "`tmplab'"
label variable rhousehold_income_remittances "`tmplab'"

gen rhousehold_income_others = household_income_others/price_indexL*100
local tmplab: variable label household_income_others
local tmplab = "`reallab'" + "`tmplab'"
label variable rhousehold_income_others "`tmplab'"

gen rhousehold_income_total = household_income_total/price_indexL*100
local tmplab: variable label household_income_total
local tmplab = "`reallab'" + "`tmplab'"
label variable rhousehold_income_total "`tmplab'"

//bring household identification variables to the front
//remove the duplicated variables during the merges
save ".//household_income_expenditure.dta", replace 
