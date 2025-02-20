@0xf5016e9c3373ab18;

struct Preferences {
    enum BundlesViewMode {
        cards @0;
        list @1;
    }
    
    enum BundlesSortOrder {
        recent @0;
        progress @1;
        alphabetical @2;
    }
    
    bundlesViewMode @0 :BundlesViewMode = cards;
    bundlesSortOrder @1 :BundlesSortOrder = recent;
    showFullTime @2 :Bool = false;
    showHiddenAchievements @3 :Bool = false;
    playMusic @4 :Bool = true;
}
