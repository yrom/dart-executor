// Copyright (c) 2019 Yrom Wang. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

List<dynamic> list1(o) => List(1)..[0] = o;

List<dynamic> list2(o1, o2) => List(2)
  ..[0] = o1
  ..[1] = o2;

List<dynamic> list3(o1, o2, o3) => List(3)
  ..[0] = o1
  ..[1] = o2
  ..[2] = o3;

List<dynamic> list4(o1, o2, o3, o4) => List(4)
  ..[0] = o1
  ..[1] = o2
  ..[2] = o3
  ..[3] = o4;
