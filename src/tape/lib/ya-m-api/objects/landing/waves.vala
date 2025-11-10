/*
 * Copyright (C) 2024 Vladimir Romanov
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

using Gee;

/**
 * Wave discovery item
 */
public class Tape.YaMAPI.Landing.WaveItem : ApiBase.DataObject {
    public Rotor.StationInfo station_info { get; set; }
    public string type_ { get; set; } // "genre", "mood", "activity", "epoch", "artist"
    public string? value { get; set; } // genre name, mood name, etc.
}

/**
 * Wave group (e.g., "mix", "genre", "mood", "activity")
 */
public class Tape.YaMAPI.Landing.WaveGroup : ApiBase.DataObject {
    public string id { get; set; } // "mix", "genre", "mood", "activity"
    public string title { get; set; } // "топ", "по жанру", "под настроение", "под занятие"
    public ArrayList<WaveItem> items { get; set; default = new ArrayList<WaveItem> (); }
}

/**
 * Waves landing block (discoveries)
 */
public class Tape.YaMAPI.Landing.Waves : ApiBase.DataObject {
    public ArrayList<WaveItem> items { get; set; default = new ArrayList<WaveItem> (); }
    public ArrayList<WaveGroup> groups { get; set; default = new ArrayList<WaveGroup> (); }
}
