/*
 *
 * Training Stats: mobile app that helps collecting data during
 * trainings of team sports.
 * Copyright (C) 2020 Carlo Ramponi, magocarlos1999@gmail.com
  * This program is free software: you can redistribute it and/or modify
  * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
  * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
  * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 * 
 */

import 'package:sqflite/sqflite.dart';
import 'package:training_stats/datatypes/action.dart';
import 'package:training_stats/datatypes/player.dart';
import 'package:training_stats/datatypes/record.dart';
import 'package:training_stats/datatypes/team.dart';
import 'package:training_stats/utils/db.dart';

class Training {

  int id;
  DateTime ts_start, ts_end;
  Team team;
  List<Player> players;
  List<Action> actions;
  List<Record> records;

  Training({
    this.id,
    this.team,
    this.players,
    this.actions,
    this.ts_start,
    this.ts_end,
    this.records
  }) {
    if(this.ts_start == null) {
      this.ts_start = DateTime.now();
    }
  }

  static Future<Training> fromMap(Map<String, dynamic> m) async {
    return Training(
        id: m['id'],
        team: await TeamProvider.get(m['team']),
        ts_start: DateTime.parse(m['ts_start']),
        ts_end: DateTime.parse(m['ts_end']),
        actions: await TrainingProvider.getActions(m['id']),
        players: await TrainingProvider.getPlayers(m['id']),
        records: await TrainingProvider.getRecords(m['id'])
    );
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> ret = {
      'team': this.team.id,
      'ts_start': this.ts_start?.toIso8601String(),
      'ts_end': this.ts_end?.toIso8601String(),
    };

    if (id != null) {
      ret['id'] = this.id;
    }

    return ret;
  }

}

class TrainingProvider {

  static Future<List<Training>> getAll() async {
    List<Map<String, dynamic>> list = await (await DB.instance).db.query('Training', orderBy: "ts_start DESC");
    List<Training> trainings = [];
    for(int i = 0; i < list.length; i++) {
      trainings.add(await Training.fromMap(list[i]));
    }
    return trainings;
  }

  static Future<Training> get(int id) async {
    Map<String, dynamic> ret = (await (await DB.instance).db.query('Training', where: "id = ?", whereArgs: [id])).first;
    return ret != null ? Training.fromMap(ret) : null;
  }

  static Future<Training> create(Training t) async {

    Database db = (await DB.instance).db;

    t.id = await db.insert('Training', t.toMap());

    t.actions.forEach((element) async {
      await db.insert('ActionTraining', {
        "action" : element.id,
        "training" : t.id
      });
    });

    t.players.forEach((element) async {
      await db.insert('PlayerTraining', {
        "player" : element.id,
        "training" : t.id
      });
    });

    for(int i = 0; i < t.records.length; i++) {
      Map<String, dynamic> map = t.records[i].toMap();
      map['training'] = t.id;
      t.records[i].id = await db.insert('Record', map);
    }

    return t;
  }

  static Future<List<Player>> getPlayers(int id) async {
    List<Map<String, dynamic>> list = await (await DB.instance).db.query('PlayerTraining', where: "training = ?", whereArgs: [id]);

    List<Player> players = [];
    for(int i = 0; i < list.length; i++) {
      players.add(await PlayerProvider.get(list[i]["player"]));
    }

    return players;
  }

  static Future<List<Action>> getActions(int id) async {
    List<Map<String, dynamic>> list = await (await DB.instance).db.query('ActionTraining', where: "training = ?", whereArgs: [id]);

    List<Action> actions = [];
    for(int i = 0; i < list.length; i++) {
      actions.add(await ActionProvider.get(list[i]["action"]));
    }

    return actions;
  }

  static Future<List<Record>> getRecords(int id) async {
    List<Map<String, dynamic>> list = await (await DB.instance).db.query('Record', where: "training = ?", whereArgs: [id]);

    List<Record> records = [];
    for(int i = 0; i < list.length; i++) {
      records.add(await Record.fromMap(list[i]));
    }

    return records;
  }

  static Future<int> delete(int id) async {
    return (await DB.instance).db.delete('Training', where: "id = ?", whereArgs: [id]);
  }

}