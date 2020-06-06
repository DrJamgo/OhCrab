<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.2" tiledversion="1.2.4" name="tiles" tilewidth="32" tileheight="32" tilecount="64" columns="8">
 <image source="tiles.png" width="256" height="256"/>
 <tile id="0">
  <objectgroup draworder="index">
   <object id="1" x="0" y="0" width="32" height="32">
    <properties>
     <property name="collidable" type="bool" value="true"/>
     <property name="dynamic" type="bool" value="true"/>
     <property name="module" value="Dirt"/>
    </properties>
   </object>
  </objectgroup>
  <animation>
   <frame tileid="0" duration="250"/>
   <frame tileid="1" duration="250"/>
  </animation>
 </tile>
 <tile id="8">
  <objectgroup draworder="index">
   <object id="1" x="0" y="0" width="32" height="32">
    <properties>
     <property name="collidable" type="bool" value="true"/>
    </properties>
   </object>
  </objectgroup>
  <animation>
   <frame tileid="8" duration="250"/>
   <frame tileid="9" duration="250"/>
  </animation>
 </tile>
 <tile id="10">
  <animation>
   <frame tileid="10" duration="250"/>
   <frame tileid="11" duration="250"/>
  </animation>
 </tile>
 <tile id="13">
  <objectgroup draworder="index">
   <object id="1" x="14" y="15.75" width="7" height="7">
    <properties>
     <property name="collidable" type="bool" value="true"/>
     <property name="dynamic" type="bool" value="true"/>
     <property name="group" type="int" value="1"/>
     <property name="module" value="Spawn"/>
    </properties>
   </object>
  </objectgroup>
 </tile>
</tileset>
