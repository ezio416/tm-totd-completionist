// c 2024-01-01
// m 2024-01-02

string accountId;
CTrackMania@ App;
string audienceCore = "NadeoServices";
string audienceLive = "NadeoLiveServices";
Map@[] maps;
dictionary mapsById;
dictionary mapsByUid;
string title = "\\$FA0" + Icons::CalendarO + "\\$G TOTD Grinder";

[Setting category="General" name="Enabled"]
bool S_Enabled = true;

void RenderMenu() {
    if (UI::MenuItem(title, "", S_Enabled))
        S_Enabled = !S_Enabled;
}

void Main() {
    if (!Permissions::PlayLocalMap()) {
        warn("plugin requires paid access to play maps");
        return;
    }

    @App = cast<CTrackMania@>(GetApp());

    accountId = App.LocalPlayerInfo.WebServicesUserId;

    NadeoServices::AddAudience(audienceCore);
    NadeoServices::AddAudience(audienceLive);

    GetMaps();
}