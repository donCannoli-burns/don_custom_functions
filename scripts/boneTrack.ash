script "boneTrack.ash"
notify "donCannoli"
import <don_bone_lib.ash>;

// color thresholds
int trigger_MallPrice_High    = 15000000;
int trigger_MallPrice_Low     =  3000000;
int trigger_MeatPerBone_High  =    10000;
int trigger_MeatPerBone_Low   =     1000;
int trigger_ValuePerBone_High =       15;
int trigger_ValuePerBone_Low  =        7;

int ownedAmount(item x) {
	return don_bone_owned_amount(x);
}

// ask once if wiki should auto-launch, store as pref
void initWikiSetting() {
	if (get_property(`boneTrackEnableWiki`) != "")
		return;
	string prompt = `Enable auto-launch of KoL Wiki\'s SoCP Daily Special page?\n` +
				`Note: after initial setup, reset this with CLI:\n` +
				`"set boneTrackEnableWiki = [false|true]"`;
	boolean enabled = user_confirm(prompt);
	set_property("boneTrackEnableWiki", enabled);
	if (enabled) {
		print(`Setting AutoLaunch [ON]`, `green`);
		print(`"set boneTrackEnableWiki=false" to turn off wiki autolaunch.`, `navy`);
	}
	else {
		print(`Setting AutoLaunch [OFF]`, `orange`);
		print(`"set boneTrackEnableWiki=true" to turn on wiki autolaunch.`, `navy`);
	}
}

// raw and computed values
record BoneStats {
	item    dailySpecial;
	boolean tradable;
	boolean purchasedSpecial;
	int     itemNumber;
	int     specialMallPrice;
	int     specialBonePrice;
	int     specialOwned;
	int     ownedBones;
	int     restBones;
	int     adventureBones;
	int     totalBones;
	float   meatPerBone;
	float   valuePerBone;
	string  legNumber;
};

BoneStats gatherStats() {
	BoneStats s;
	item kb = $item[knucklebone];
	string specialItem = get_property("_crimboPastDailySpecialItem");
	s.dailySpecial = specialItem.to_item();
	s.itemNumber = specialItem.to_int();
	s.tradable = is_tradeable(s.dailySpecial);
	s.purchasedSpecial = get_property("_crimboPastDailySpecial").to_boolean();
	s.specialBonePrice = get_property("_crimboPastDailySpecialPrice").to_int();
	s.specialMallPrice = s.tradable ? mall_price(s.dailySpecial) : 0;
	s.specialOwned = ownedAmount(s.dailySpecial);
	s.ownedBones = ownedAmount(kb);
	s.totalBones = don_bone_daily_drops();
	s.restBones = don_bone_rest_drops();
	s.adventureBones = s.totalBones - s.restBones;
	s.meatPerBone = (s.specialBonePrice > 0)
		? to_int(s.specialMallPrice / s.specialBonePrice)
		: 0;
	// Preserve the original VPB calculation, but use normal arithmetic
	// and avoid dividing by zero when no usable mall value exists.
	s.valuePerBone = (s.meatPerBone > 0)
		? (s.specialMallPrice / (s.meatPerBone + 1.0)) / 100.0
		: 0;
	s.legNumber = "Leg" + (get_property("ascensionsToday").to_int() + 1);
	return s;
}

void updateMetricLog(string filePath, string key, float value) {
	string[string] data;
	file_to_map(filePath, data);
	data[key] = value;
	map_to_file(data, filePath);
}

// file logging daily-special snapshot and rolling MPB/VPB
void logDailyData(BoneStats s) {
	string base = "/boneTrack/" + my_name();
	string today = today_to_string();
	string itemKey = today + "_" + s.itemNumber;
	string[string] boneData;
	boneData["1. " + s.dailySpecial + " Bone Price:"]  = s.specialBonePrice;
	boneData["2. " + s.dailySpecial + " Mall Price:"]  = s.specialMallPrice;
	boneData["3. Total Inventory Knucklebones:"]       = s.ownedBones;
	boneData["4. Meat/Per/Knucklebone:"]               = s.meatPerBone;
	boneData["5. Value/Per/Knucklebone:"]              = s.valuePerBone;
	boneData["6. Daily Collected Knucklebone:"]        = s.totalBones;
	boneData["7. #/of Daily-Special Owned:"]           = s.specialOwned;
	boneData["8. #/of Daily-Special Buy w/Bones:"]     = s.purchasedSpecial.to_int();
	map_to_file(boneData, `{base}/DailySpecial Tracking/{s.dailySpecial}_{s.itemNumber}/{today}_{s.legNumber}.txt`);

	// purchase log (only when we actually bought with bones today)
	if (s.purchasedSpecial) {
		string buyPath = base + "/BoneValue Tracking/BUY.txt";
		string[string] boneBuyData;
		file_to_map(buyPath, boneBuyData);
		boneBuyData[itemKey + " Purchased: Qty[" + s.purchasedSpecial.to_int() + "] For"] = s.specialBonePrice + " Knucklebones.";
		boneBuyData[itemKey + " Owned: Qty[" + s.specialOwned + "] Mall Price:"] = s.specialMallPrice;
		map_to_file(boneBuyData, buyPath);
	}

	// rolling meat-per-bone / value-per-bone logs
	updateMetricLog(base + "/BoneValue Tracking/MPB.txt", itemKey + " MPB:", s.meatPerBone);
	updateMetricLog(base + "/BoneValue Tracking/VPB.txt", itemKey + " VPB:", s.valuePerBone);
}


// compute historical averages
record Averages {
	float vpb;
	float mpb;
};

float averageFromFile(string filePath, string label) {
	float total = 0;
	int count = 0;
	float[string] data;
	file_to_map(filePath, data);

	foreach key, value in data {
		total += value;
		count++;
	}

	if (count == 0) {
		print("No " + label + " data found.");
		return 0;
	}

	return total / count;
}

Averages computeAverages() {
	string base = "/boneTrack/" + my_name() + "/BoneValue Tracking/";
	Averages avg;
	avg.vpb = averageFromFile(base + "VPB.txt", "VPB");
	avg.mpb = averageFromFile(base + "MPB.txt", "MPB");
	return avg;
}

void printByThreshold(string message, float value, float low, float high) {
	if (value > high)
		print(message, "green");
	else if (value < low)
		print(message, "red");
	else
		print(message, "navy");
}

// print colorful CLI
void printReport(BoneStats s, Averages avg) {
	string bar  = `|= == == == == == == = | > KNUCKLEBONE DAILY BREAKDOWN < |= == == == == == == |`;
	string div  = `-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --`;
	string foot = `|= == == == == == == == == == == == == == == == == == == == == == == == == == == = |`;
	// header
	print(bar, 'navy');
	print(div, 'orange');
	// bone inventory & daily collection
	print(`> Total Knucklebones in Inventory: [{s.ownedBones}]`, 'navy');
	print(`> Daily Knucklebone Collection:`, 'navy');
	print(`>   "Adv-Bones"  : [{s.adventureBones}/ 95]`, 'navy');
	print(`>   "Rest-Bones" : [{s.restBones}/ 5]`,  'navy');
	string collectedMsg = `> [{s.totalBones}/ 100] Knucklebones Collected For The Day.`;
	print(collectedMsg, (s.totalBones == 100) ? 'green' : 'red');
	print(div, 'orange');
	// affordability
	print(`> The Daily Special Is: [{s.dailySpecial}].`, 'navy');
	print(`> Knucklebone Price Of: [{s.specialBonePrice}] Knucklebones.`, 'navy');
	boolean canAfford = s.specialBonePrice > 0 && s.ownedBones >= s.specialBonePrice;
	string affordMsg = `> You [CAN{canAfford ? "" : "NOT"}] Afford The Daily Special: {s.dailySpecial}!`;
	print(affordMsg, canAfford ? 'green' : 'red');
	print(div, 'orange');
	// value metrics
	if (s.tradable) {
		string mallMsg = `> Mall Price Of: [{s.specialMallPrice}] Meat.`;
		string mpbMsg = `> That\'s A Return Of: [{s.meatPerBone}] Meat/Per/Knucklebone!`;
		string vpbMsg = `> A Value Of [{to_string(s.valuePerBone, "%.3f")}%] Per/Knucklebone.` +
						`(SpecialMallPrice / MeatPerBone) / 100`;
		printByThreshold(mallMsg, s.specialMallPrice, trigger_MallPrice_Low, trigger_MallPrice_High);
		printByThreshold(mpbMsg, s.meatPerBone, trigger_MeatPerBone_Low, trigger_MeatPerBone_High);
		printByThreshold(vpbMsg, s.valuePerBone, trigger_ValuePerBone_Low, trigger_ValuePerBone_High);
	}
	else
		print(`> {s.dailySpecial} is Not Tradable.`, 'navy');
	print(div, 'orange');
	// ownership & purchase
	string ownMsg = `> We Own [{s.specialOwned}] {s.dailySpecial}`;
	print(ownMsg, s.specialOwned > 0 ? 'green' : 'red');
	print(`> We {(s.purchasedSpecial) ? "[HAVE]" : "[HAVE NOT]"} Purchased {s.dailySpecial} With Knucklebones.`,
		s.purchasedSpecial ? 'green' : 'red');
	print(div, 'orange');
	// historical averages
	print(`> As of: [{today_to_string()}]`, 'navy');
	print(`> Average "Daily Special" Meat / Per / Knucklebone : [{to_string(avg.mpb, "%.3f")}]`, 'navy');
	print(`> Average "Daily Special" Value / Per / Knucklebone: [{to_string(avg.vpb, "%.3f")}]`, 'navy');
	print(div, 'orange');
	print(foot, 'navy');
}

// optional wiki launcher
void maybeOpenWiki(item dailySpecial) {
	if (get_property("boneTrackEnableWiki").to_boolean())
		cli_execute(`lookup ` + dailySpecial);
}

void main() {
	initWikiSetting();
	BoneStats s = gatherStats();
	logDailyData(s);
	Averages avg = computeAverages();
	printReport(s, avg);
	maybeOpenWiki(s.dailySpecial);
}
