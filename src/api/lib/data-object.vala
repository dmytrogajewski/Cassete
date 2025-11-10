/*
 * Copyright (C) 2025 Vladimir Romanov <rirusha@altlinux.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see
 * <https://www.gnu.org/licenses/gpl-3.0-standalone.html>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

/**
 * A class with convenient methods for fast de/serialization
 */
public abstract class ApiBase.DataObject : Object {

    /**
     * Parse json and fill up this object via
     * {@link Jsoner.deserialize_object_into}
     *
     * @throws JsonError    Error with json or sub_members
     */
    public void fill_from_json (
        string json,
        string[]? sub_members = null,
        Case names_case = Case.AUTO
    ) throws JsonError {
        var jsoner = new Jsoner (json, sub_members, names_case);
        jsoner.deserialize_object_into (this);
    }

    /**
     * Serialize object to json
     */
    public string to_json (Case names_case = Case.AUTO) {
        return Jsoner.serialize (this, names_case);
    }
}
