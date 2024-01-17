// c 2024-01-01
// m 2024-01-16

string     accountId;
bool       allTarget       = false;
string     audienceCore    = "NadeoServices";
string     audienceLive    = "NadeoLiveServices";
bool       club            = false;
string     colorMedalAuthor;
string     colorMedalBronze;
string     colorMedalGold;
string     colorMedalNone;
string     colorMedalSilver;
string     colorTarget;
string     currentUid;
bool       gettingNow      = false;
Map@[]     maps;
Map@[]     mapsCampaign;
dictionary mapsCampaignById;
dictionary mapsCampaignByUid;
Map@[]     mapsRemaining;
Map@[]     mapsTotd;
dictionary mapsTotdById;
dictionary mapsTotdByUid;
uint       metTargetTotal  = 0;
Map@       nextMap;
string     title           = "\\$0F0" + Icons::Check + "\\$G Campaign Completionist";

void Main() {
    if (Permissions::PlayLocalMap())
        club = true;
    else {
        warn("Club access required to play maps");

        if (S_NotifyStarter)
            UI::ShowNotification(title, "Club access is required to play maps, but you can still track your progress on the current Nadeo Campaign", vec4(1.0f, 0.1f, 0.1f, 0.8f));
    }

    lastMode = S_Mode;
    lastOnlyCurrentCampaign = S_OnlyCurrentCampaign;
    OnSettingsChanged();

    accountId = GetApp().LocalPlayerInfo.WebServicesUserId;

    NadeoServices::AddAudience(audienceCore);
    NadeoServices::AddAudience(audienceLive);

    GetMaps();

    while (true) {
        Loop();
        yield();
    }
}

void RenderMenu() {
    if (UI::BeginMenu(title)) {
        if (club) {
            if (S_MenuAutoSwitch && UI::MenuItem(Icons::Question + " Auto Switch Maps", "", S_AutoSwitch))
                S_AutoSwitch = !S_AutoSwitch;

            if (UI::MenuItem(
                S_Mode == Mode::NadeoCampaign ? "\\$1D4" + Icons::Kenney::Car + " Mode: Nadeo Campaign" : "\\$19F" + Icons::Calendar + " Mode: Track of the Day",
                "",
                false,
                !gettingNow
            )) {
                S_Mode = S_Mode == Mode::NadeoCampaign ? Mode::TrackOfTheDay : Mode::NadeoCampaign;
                OnSettingsChanged();
            }

            if (S_MenuOnlyCurrentCampaign && S_Mode == Mode::NadeoCampaign && UI::MenuItem(Icons::ClockO + " Only Current Campaign", "", S_OnlyCurrentCampaign)) {
                S_OnlyCurrentCampaign = !S_OnlyCurrentCampaign;
                startnew(SetNextMap);
            }
        } else {
            UI::MenuItem("\\$1D4" + Icons::ArrowsH + " Mode: Nadeo Campaign", "", false, false);

            if (S_Mode == Mode::TrackOfTheDay)
                S_Mode = Mode::NadeoCampaign;
        }

        if (S_MenuRefresh && UI::MenuItem(Icons::Refresh + " Refresh Records", "", false, !gettingNow))
            startnew(RefreshRecords);

        if (UI::BeginMenu(colorTarget + Icons::Circle + " Target Medal: " + tostring(S_Target))) {
            if (UI::MenuItem(colorMedalAuthor + Icons::Circle + " Author", "")) {
                S_Target = TargetMedal::Author;
                OnSettingsChanged();
                startnew(SetNextMap);
            }
            if (UI::MenuItem(colorMedalGold + Icons::Circle + " Gold", "")) {
                S_Target = TargetMedal::Gold;
                OnSettingsChanged();
                startnew(SetNextMap);
            }
            if (UI::MenuItem(colorMedalSilver + Icons::Circle + " Silver", "")) {
                S_Target = TargetMedal::Silver;
                OnSettingsChanged();
                startnew(SetNextMap);
            }
            if (UI::MenuItem(colorMedalBronze + Icons::Circle + " Bronze", "")) {
                S_Target = TargetMedal::Bronze;
                OnSettingsChanged();
                startnew(SetNextMap);
            }
            if (UI::MenuItem(colorMedalNone + Icons::Circle + " None", "")) {
                S_Target = TargetMedal::None;
                OnSettingsChanged();
                startnew(SetNextMap);
            }
            UI::EndMenu();
        }

        UI::MenuItem(
            Icons::Percent + " Progress: " + (gettingNow ? "..." : metTargetTotal + "/" + maps.Length + " (" + (int(100 * metTargetTotal / maps.Length)) +"%)"),
            "",
            false,
            false
        );

        string nextText = "\\$0F0" + Icons::Play + "\\$G Next: ";

        if (gettingNow)
            nextText += "\\$AAAstill getting data...";
        else if (nextMap !is null) {
            nextText += S_Mode == Mode::NadeoCampaign ? "" : nextMap.date + ": ";
            nextText += S_ColorMapNames ? nextMap.nameColored : nextMap.nameClean;
            nextText += nextMap.uid == currentUid ? "\\$G (current)" : "";
        } else
            nextText += "you're done!";

        if (UI::MenuItem(nextText, "", false, club && !gettingNow && !loadingMap && !allTarget && nextMap !is null && nextMap.uid != currentUid))
            startnew(CoroutineFunc(nextMap.Play));

        if (S_MenuAllMaps && mapsRemaining.Length > 0) {
            if (UI::BeginMenu(Icons::List + " Remaining Maps (" + mapsRemaining.Length + ")", !gettingNow)) {
                for (uint i = 0; i < mapsRemaining.Length; i++) {
                    Map@ map = mapsRemaining[i];

                    if (UI::MenuItem(S_Mode == Mode::NadeoCampaign ? map.nameClean : map.date + ": " + (S_ColorMapNames ? map.nameColored : map.nameClean), "", false, club))
                        startnew(CoroutineFunc(map.Play));
                }

                UI::EndMenu();
            }
        }

        UI::EndMenu();
    }
}

void Render() {
    RenderDebug();
}

void OnSettingsChanged() {
    if (lastMode != S_Mode || lastOnlyCurrentCampaign != S_OnlyCurrentCampaign) {
        lastMode = S_Mode;
        lastOnlyCurrentCampaign = S_OnlyCurrentCampaign;
        startnew(SetNextMap);
    }

    colorMedalAuthor = "\\" + Text::FormatGameColor(S_ColorMedalAuthor);
    colorMedalGold   = "\\" + Text::FormatGameColor(S_ColorMedalGold);
    colorMedalSilver = "\\" + Text::FormatGameColor(S_ColorMedalSilver);
    colorMedalBronze = "\\" + Text::FormatGameColor(S_ColorMedalBronze);
    colorMedalNone   = "\\" + Text::FormatGameColor(S_ColorMedalNone);

    switch (S_Target) {
        case TargetMedal::Author: colorTarget = colorMedalAuthor; break;
        case TargetMedal::Gold:   colorTarget = colorMedalGold;   break;
        case TargetMedal::Silver: colorTarget = colorMedalSilver; break;
        case TargetMedal::Bronze: colorTarget = colorMedalBronze; break;
        default:                  colorTarget = colorMedalNone;
    }
}

void Loop() {
    if (!club) {
        if (S_AutoSwitch)
            S_AutoSwitch = false;

        if (S_MenuAutoSwitch)
            S_MenuAutoSwitch = false;

        if (S_MenuOnlyCurrentCampaign)
            S_MenuOnlyCurrentCampaign = false;

        if (S_Mode == Mode::TrackOfTheDay)
            S_Mode = Mode::NadeoCampaign;

        if (!S_OnlyCurrentCampaign)
            S_OnlyCurrentCampaign = true;
    }

    CTrackMania@ App = cast<CTrackMania@>(GetApp());

    if (App.RootMap is null || App.RootMap.MapInfo is null) {
        currentUid = "";
        return;
    }

    if (loadingMap)
        return;

    currentUid = App.RootMap.MapInfo.MapUid;

    if (nextMap is null
        || nextMap.uid != currentUid
        || App.Network is null
        || App.Network.ClientManiaAppPlayground is null
        || App.Network.ClientManiaAppPlayground.ScoreMgr is null
        || App.Network.ClientManiaAppPlayground.UI is null
        || App.Network.ClientManiaAppPlayground.UI.UISequence != CGamePlaygroundUIConfig::EUISequence::Finish
        || App.UserManagerScript is null
        || App.UserManagerScript.Users.Length == 0
    )
        return;

    trace("run finished, getting PB on current map");

    uint prevTime = nextMap.myTime;

    for (uint i = 0; i < 20; i++)
        yield();  // allow game to process PB

    nextMap.myTime = App.Network.ClientManiaAppPlayground.ScoreMgr.Map_GetRecord_v2(App.UserManagerScript.Users[0].Id, currentUid, "PersonalBest", "", "TimeAttack", "");
    nextMap.SetMedals();

    Meta::PluginCoroutine@ coro = startnew(SetNextMap);
    while (coro.IsRunning())
        yield();

    if (nextMap.uid != currentUid) {
        Notify();

        if (S_AutoSwitch && club) {
            startnew(CoroutineFunc(nextMap.Play));
            sleep(10000);  // give some time for next map to load before checking again
        }
    } else
        NotifyTimeNeeded(prevTime == 0 || nextMap.myTime < prevTime);

    try {
        while (
            App.Network.ClientManiaAppPlayground.UI.UISequence == CGamePlaygroundUIConfig::EUISequence::Finish ||
            App.Network.ClientManiaAppPlayground.UI.UISequence == CGamePlaygroundUIConfig::EUISequence::EndRound
        )
            yield();
    } catch {
        return;
    }
}

void SetNextMap() {
    while (gettingNow)
        yield();

    trace("setting next map");

    metTargetTotal = 0;
    @nextMap = null;
    uint target = 4 - S_Target;

    mapsRemaining.RemoveRange(0, mapsRemaining.Length);

    if (!club) {
        if (S_Mode == Mode::TrackOfTheDay)
            S_Mode = Mode::NadeoCampaign;

        if (!S_OnlyCurrentCampaign)
            S_OnlyCurrentCampaign = true;
    }

    maps = S_Mode == Mode::NadeoCampaign ? mapsCampaign : mapsTotd;

    if (S_Mode == Mode::NadeoCampaign && S_OnlyCurrentCampaign && maps.Length >= 25)
        maps.RemoveRange(0, maps.Length - 25);

    if (!club)
        maps.RemoveRange(10, 15);

    for (uint i = 0; i < maps.Length; i++) {
        if (S_Target == TargetMedal::None) {
            if (maps[i].myTime > 0) {
                metTargetTotal++;
                continue;
            }
        } else if (maps[i].myMedals >= target) {
            metTargetTotal++;
            continue;
        }

        mapsRemaining.InsertLast(maps[i]);

        if (nextMap is null)
            @nextMap = maps[i];
    }

    if (metTargetTotal == maps.Length) {
        allTarget = true;
        trace("congrats, you've met your target on all maps!");
    } else {
        allTarget = false;
        if (nextMap !is null)
            trace("next map: " + nextMap.date + ": " + nextMap.nameClean);
    }
}