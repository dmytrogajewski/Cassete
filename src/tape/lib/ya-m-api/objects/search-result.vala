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
 * Search result item from /search/instant/mixed endpoint
 */
public class Tape.YaMAPI.SearchResultItem : ApiBase.DataObject {
    public string type_ { get; set; }
    public Track? track { get; set; }
}

/**
 * Search response from /search/instant/mixed endpoint
 */
public class Tape.YaMAPI.SearchResponse : ApiBase.DataObject {
    public ArrayList<SearchResultItem> results { get; set; default = new ArrayList<SearchResultItem> (); }
}
