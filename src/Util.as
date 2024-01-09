// c 2024-01-02
// m 2024-01-08

void Notify() {
    switch (S_Target) {
        case TargetMedal::Author: NotifyAuthor(); break;
        case TargetMedal::Gold:   NotifyGold();   break;
        case TargetMedal::Silver: NotifySilver(); break;
        case TargetMedal::Bronze: NotifyBronze(); break;
        default:                  NotifyNone();
    }
}

void NotifyAuthor() {
    UI::ShowNotification(title, "Author achieved!" + (S_AutoSwitch ? " Switching map..." : ""), vec4(S_ColorMedalAuthor.x, S_ColorMedalAuthor.y, S_ColorMedalAuthor.z, 0.8f));
}

void NotifyGold() {
    UI::ShowNotification(title, "Gold achieved!" + (S_AutoSwitch ? " Switching map..." : ""), vec4(S_ColorMedalGold.x, S_ColorMedalGold.y, S_ColorMedalGold.z, 0.8f));
}

void NotifySilver() {
    UI::ShowNotification(title, "Silver achieved!" + (S_AutoSwitch ? " Switching map..." : ""), vec4(S_ColorMedalSilver.x, S_ColorMedalSilver.y, S_ColorMedalSilver.z, 0.8f));
}

void NotifyBronze() {
    UI::ShowNotification(title, "Bronze achieved!" + (S_AutoSwitch ? " Switching map..." : ""), vec4(S_ColorMedalBronze.x, S_ColorMedalBronze.y, S_ColorMedalBronze.z, 0.8f));
}

void NotifyNone() {
    UI::ShowNotification(title, "Map finished!" + (S_AutoSwitch ? " Switching map..." : ""), vec4(S_ColorMedalNone.x, S_ColorMedalNone.y, S_ColorMedalNone.z, 0.8f));
}

void NotifyTimeNeeded(bool pb) {
    if (
        S_NotifyAfterRun == NotifyAfterRun::Never ||
        (S_NotifyAfterRun == NotifyAfterRun::OnlyAfterPB && !pb)
    )
        return;

    int target;

    switch (S_Target) {
        case TargetMedal::Author: target = nextMap.authorTime; break;
        case TargetMedal::Gold:   target = nextMap.goldTime;   break;
        case TargetMedal::Silver: target = nextMap.silverTime; break;
        case TargetMedal::Bronze: target = nextMap.bronzeTime; break;
        default: target = 0;
    }

    string text = (pb ? "Better, but y" : "Not fast enough! Y") + "ou still need " + Time::Format(int(nextMap.myTime) - target) + " for " + tostring(S_Target);
    trace(text);
    UI::ShowNotification(title, text, vec4(S_ColorTimeNeeded.x, S_ColorTimeNeeded.y, S_ColorTimeNeeded.z, 0.8f));
}

// courtesy of "BetterTOTD" plugin - https://github.com/XertroV/tm-better-totd
void ReturnToMenu() {
    CTrackMania@ App = cast<CTrackMania@>(GetApp());

    if (App.Network.PlaygroundClientScriptAPI.IsInGameMenuDisplayed)
        App.Network.PlaygroundInterfaceScriptHandler.CloseInGameMenu(CGameScriptHandlerPlaygroundInterface::EInGameMenuResult::Quit);

    App.BackToMainMenu();

    while (!App.ManiaTitleControlScriptAPI.IsReady)
        yield();
}

string TimeFormatColored(uint u, bool format = true) {
    if (u > 0)
        return "\\$0F0" + (format ? Time::Format(u) : tostring(u));

    if (u < 0)
        return "\\$F00" + (format ? Time::Format(Math::Abs(u)) : tostring(Math::Abs(u)));

    return "\\$G0" + (format ? ":00.000" : "");
}

string ZPad2(int num) {
    return (num < 10 ? "0" : "") + num;
}

string ZPad4(int num) {
    return (num < 10 ? "000" : num < 100 ? "00" : num < 1000 ? "0" : "") + num;
}