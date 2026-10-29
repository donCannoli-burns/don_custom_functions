script "relay_BoneTrack.ash"
notify "donCannoli"

buffer page;

string html(string value) {
	return entity_encode(value);
}

float meanValue(float[string] values) {
	if (count(values) == 0)
		return 0;

	float total = 0;
	foreach key, value in values
		total += value;

	return total / count(values);
}

void appendStyles() {
	page.append("<style>");
	page.append("html,body{margin:0;padding:0;background:#f4f6f8;color:#17202a;font-family:Arial,Helvetica,sans-serif;}");
	page.append("body{padding:18px;}");
	page.append(".wrap{max-width:1100px;margin:0 auto;}");
	page.append(".hero{background:#102a43;color:#fff;border-radius:12px;padding:20px 24px;box-shadow:0 2px 8px rgba(0,0,0,.14);}");
	page.append(".hero h1{margin:0 0 6px;font-size:28px;}");
	page.append(".hero p{margin:0;color:#d9e2ec;}");
	page.append(".toolbar{display:flex;gap:10px;align-items:center;margin:14px 0 18px;flex-wrap:wrap;}");
	page.append(".button{display:inline-block;background:#f59e0b;color:#111827;text-decoration:none;font-weight:bold;padding:8px 12px;border-radius:7px;}");
	page.append(".tag{display:inline-block;background:#e7eef5;color:#334e68;padding:6px 9px;border-radius:999px;font-size:12px;}");
	page.append(".grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(190px,1fr));gap:12px;margin:0 0 18px;}");
	page.append(".card{background:#fff;border:1px solid #d9e2ec;border-radius:10px;padding:14px 16px;box-shadow:0 1px 3px rgba(0,0,0,.06);}");
	page.append(".card .label{font-size:12px;text-transform:uppercase;letter-spacing:.06em;color:#627d98;}");
	page.append(".card .value{font-size:24px;font-weight:bold;color:#102a43;margin-top:5px;}");
	page.append("details{background:#fff;border:1px solid #d9e2ec;border-radius:10px;margin:12px 0;overflow:hidden;}");
	page.append("summary{cursor:pointer;padding:14px 16px;font-weight:bold;background:#eaf0f6;color:#243b53;}");
	page.append(".section{padding:14px 16px;}");
	page.append(".file{font-family:monospace;font-size:12px;color:#52667a;word-break:break-all;margin:0 0 10px;}");
	page.append(".empty{padding:16px;background:#fff8e8;border-left:4px solid #f59e0b;color:#7c5a10;}");
	page.append(".tablewrap{overflow:auto;max-height:440px;border:1px solid #e4e7eb;border-radius:7px;}");
	page.append("table{width:100%;border-collapse:collapse;font-size:13px;background:#fff;}");
	page.append("th,td{padding:8px 10px;border-bottom:1px solid #e4e7eb;text-align:left;vertical-align:top;}");
	page.append("th{position:sticky;top:0;background:#243b53;color:#fff;z-index:1;}");
	page.append("tr:nth-child(even) td{background:#f8fafc;}");
	page.append(".num{text-align:right;font-family:monospace;white-space:nowrap;}");
	page.append(".foot{margin:20px 0 6px;color:#627d98;font-size:12px;text-align:center;}");
	page.append("</style>");
}

void appendStringMap(string title, string fileName, string[string] values, boolean openSection) {
	page.append("<details");
	if (openSection)
		page.append(" open");
	page.append("><summary>" + html(title) + " &mdash; " + count(values) + " rows</summary>");
	page.append("<div class='section'><div class='file'>data" + html(fileName) + "</div>");

	if (count(values) == 0) {
		page.append("<div class='empty'>No data found in this file yet.</div>");
	}
	else {
		page.append("<div class='tablewrap'><table><thead><tr><th>Field</th><th>Value</th></tr></thead><tbody>");
		foreach key, value in values {
			page.append("<tr><td>" + html(key) + "</td><td>" + html(value) + "</td></tr>");
		}
		page.append("</tbody></table></div>");
	}

	page.append("</div></details>");
}

void appendFloatMap(string title, string fileName, float[string] values) {
	page.append("<details><summary>" + html(title) + " &mdash; " + count(values) + " rows</summary>");
	page.append("<div class='section'><div class='file'>data" + html(fileName) + "</div>");

	if (count(values) == 0) {
		page.append("<div class='empty'>No data found in this file yet.</div>");
	}
	else {
		page.append("<div class='tablewrap'><table><thead><tr><th>Entry</th><th class='num'>Value</th></tr></thead><tbody>");
		foreach key, value in values
			page.append("<tr><td>" + html(key) + "</td><td class='num'>" + to_string(value, "%.3f") + "</td></tr>");
		page.append("</tbody></table></div>");
	}

	page.append("</div></details>");
}

void main() {
	string baseDir = "/boneTrack/" + my_name();
	string valueDir = baseDir + "/BoneValue Tracking/";
	string specialProperty = get_property("_crimboPastDailySpecialItem");
	item dailySpecial = specialProperty.to_item();
	int itemNumber = specialProperty.to_int();
	string legNumber = "Leg" + (get_property("ascensionsToday").to_int() + 1);
	string today = today_to_string();
	string snapshotFile = baseDir + "/DailySpecial Tracking/" + dailySpecial + "_" + itemNumber + "/" + today + "_" + legNumber + ".txt";

	string[string] snapshot;
	string[string] purchases;
	float[string] mpb;
	float[string] vpb;
	file_to_map(snapshotFile, snapshot);
	file_to_map(valueDir + "BUY.txt", purchases);
	file_to_map(valueDir + "MPB.txt", mpb);
	file_to_map(valueDir + "VPB.txt", vpb);

	page.append("<!doctype html><html><head><meta charset='utf-8'>");
	page.append("<meta name='viewport' content='width=device-width,initial-scale=1'>");
	page.append("<title>BoneTrack</title>");
	appendStyles();
	page.append("</head><body><div class='wrap'>");

	page.append("<div class='hero'><h1>BoneTrack</h1>");
	page.append("<p>Read-only view of the Skeleton of Crimbo Past tracking data for " + html(my_name()) + ".</p></div>");

	page.append("<div class='toolbar'>");
	page.append("<a class='button' href='relay_BoneTrack.ash?relay=true'>Refresh data</a>");
	page.append("<span class='tag'>Read only</span>");
	page.append("<span class='tag'>" + html(today) + "</span>");
	page.append("</div>");

	page.append("<div class='grid'>");
	page.append("<div class='card'><div class='label'>Daily Special</div><div class='value'>" + html(dailySpecial.to_string()) + "</div></div>");
	page.append("<div class='card'><div class='label'>Current Snapshot</div><div class='value'>" + (count(snapshot) > 0 ? "Found" : "Not logged") + "</div></div>");
	page.append("<div class='card'><div class='label'>MPB History</div><div class='value'>" + count(mpb) + "</div></div>");
	page.append("<div class='card'><div class='label'>Average MPB</div><div class='value'>" + to_string(meanValue(mpb), "%.3f") + "</div></div>");
	page.append("<div class='card'><div class='label'>VPB History</div><div class='value'>" + count(vpb) + "</div></div>");
	page.append("<div class='card'><div class='label'>Average VPB</div><div class='value'>" + to_string(meanValue(vpb), "%.3f") + "</div></div>");
	page.append("</div>");

	appendStringMap("Current Daily Snapshot", snapshotFile, snapshot, true);
	appendStringMap("Daily-Special Purchase Log", valueDir + "BUY.txt", purchases, false);
	appendFloatMap("Meat Per Knucklebone History", valueDir + "MPB.txt", mpb);
	appendFloatMap("Value Per Knucklebone History", valueDir + "VPB.txt", vpb);

	page.append("<div class='foot'>BoneTrack relay dashboard &bull; reads existing data files only</div>");
	page.append("</div></body></html>");
	writeln(page);
}
