import { getPlayerAddress } from "../../editor/lib/components";
import { InitDojo } from "../dojo";
import { ToriiQueryBuilder } from "@dojoengine/sdk";
import { SchemaType, ParentToChildren, Entity,Exit } from "@/lib/dojo_bindings/typescript/models.gen";
import { ClauseBuilder } from "@dojoengine/sdk";
import { bigintToAddress, bigintToHex128 } from "@/lib/utils/utils";
import { ExitInfo } from "../stores/terminal.uiPanel.store";
import { stringCairoEnum } from "@/editor/lib/schemas";

const normalizeAddressZero = (addr: string): string => {
  return addr.replace(/^0x0+/, "0x").toLowerCase();
}

// Player location
export const queryPlayerLocationPerGame = async (gameId: bigint): Promise<[(string | undefined), (bigint| undefined), (bigint | undefined)]> => {
  // console.log("DEBUG: queryPlayerLocationPerGame() gameId: ", gameId);
  let player_location: string | undefined;
  let location_inst: bigint | undefined;
  let playerInst: bigint | undefined;
  const player_address = getPlayerAddress();
  // console.log("DEBUG: queryPlayerLocationPerGame() player_address: ", player_address);
  try {
    // 1. Get the original player component
    const { sdk } = await InitDojo();
    const query_player = new ToriiQueryBuilder<SchemaType>()
      .withCursor("")
      .withLimit(1000)
      .includeHashedKeys()
      .withEntityModels(["lore-Player"]);
    const result_player = await sdk.getEntities({ query: query_player });
    // console.log("DEBUG: queryPlayerLocationPerGame() result_player: ", result_player);

    const player = result_player.getItems().find((item) => {
      const addr = item.models?.lore?.Player?.address;
      return addr ? normalizeAddressZero(addr) === player_address : false;
    });
    // console.log("DEBUG: queryPlayerLocationPerGame() player: ", player);

    playerInst = BigInt(player?.models?.lore?.Player?.inst ?? 0);
    // console.log("DEBUG: queryPlayerLocationPerGame() playerInst: ", playerInst);
    if (!playerInst) {
      console.error("ERROR: queryPlayerLocationPerGame() playerInst is undefined");
      return ([undefined, undefined, undefined]);
    }
    // console.log("DEBUG: queryPlayerLocationPerGame() playerInst: ", playerInst);

    // query game instance map player
    let game_inst_map: bigint = await queryGameInstaceMapByPlayer(gameId, playerInst);
    // console.log("DEBUG: queryPlayerLocationPerGame() game_inst_map.inst: ", game_inst_map);

    // query player location
    const player_location_inst = await queryPlayerLocationGIMap(game_inst_map, playerInst);
    // console.log("DEBUG: queryPlayerLocationGIMap() player_location_inst: ", player_location_inst);

    // query player location entity
    const player_location_entity = await queryPlayerLocationEntityGIMap(game_inst_map, player_location_inst);
    //console.log("DEBUG: queryPlayerLocationEntityGIMap() player_location_entity: ", player_location_entity);

    player_location = player_location_entity;
    location_inst = player_location_inst;
  } catch (error) {
    console.error("Error fetching player location from Torii:", error);
    throw error;
  }
  return ([player_location, location_inst, playerInst]);
}

export const queryGameInstaceMapByPlayer = async (gameId: bigint, inst: bigint): Promise<bigint> => {
  let game_inst_map: bigint = 0n;
  try{
    const { sdk } = await InitDojo();
    // Get the game instance using the coins entity and the game id
    const query_player_game_inst = new ToriiQueryBuilder<SchemaType>()
      .withCursor("")
      .withLimit(1000)
      .includeHashedKeys()
      .withClause(
        new ClauseBuilder<SchemaType>().keys(
          ["lore-GameInstanceMap"],
          [bigintToHex128(gameId), bigintToAddress(inst)]
        ).build()
      ).withEntityModels(["lore-GameInstanceMap"]);
    
    const result_player_game_inst = await sdk.getEntities({ query: query_player_game_inst });
    game_inst_map = BigInt(result_player_game_inst.getItems().at(0)?.models?.lore?.GameInstanceMap?.game_inst ?? 0);
    
  } catch (error) {
    console.error("Error fetching game instance map from Torii:", error);
    throw error;
  }
  return game_inst_map; 
};

export const queryPlayerLocationGIMap = async (gameInst: bigint, origInst: bigint): Promise<bigint> => {
  let player_location: bigint = 0n;
  try{
    const { sdk } = await InitDojo();
    const queryValue = gameInst != 0n ? gameInst : origInst;
    const query_playerComp = new ToriiQueryBuilder<SchemaType>()
      .withCursor("")
      .withLimit(1000)
      .includeHashedKeys()
      .withClause(
        new ClauseBuilder<SchemaType>().keys(
          ["lore-Player"],
          [bigintToHex128(queryValue)]
        ).build()
      ).withEntityModels(["lore-Player"]);
      
      
      const result_playerComp = await sdk.getEntities({ query: query_playerComp });
      console.log("DEBUG: queryPlayerLocationGIMap() result_playerComp: ", result_playerComp);

      player_location = BigInt(result_playerComp.getItems().at(0)?.models?.lore?.Player?.location ?? 0);
  } catch (error) {
    console.error("Error fetching player location item from Torii:", error);
    throw error;
  }
  return player_location;
};

export const queryPlayerLocationEntityGIMap = async (gameInst: bigint, origInst: bigint): Promise<string> => {
  let location_name: string = "";
  try{
    const { sdk } = await InitDojo();
    // get invItem
    const queryValue = gameInst != 0n ? gameInst : origInst;
    const query_Entity = new ToriiQueryBuilder<SchemaType>()
      .withCursor("")
      .withLimit(1000)
      .includeHashedKeys()
      .withClause(
        new ClauseBuilder<SchemaType>().keys(
          ["lore-Entity"],
          [bigintToHex128(queryValue)]
        ).build()
      ).withEntityModels(["lore-Entity"]);
      
      
      const result_query_Entity = await sdk.getEntities({ query: query_Entity });
      console.log("DEBUG: queryPlayerLocationEntityGIMap() result_query_Entity: ", result_query_Entity);

      location_name = (result_query_Entity.getItems().at(0)?.models?.lore?.Entity?.name ?? "undefined");
  } catch (error) {
    console.error("Error fetching player location item from Torii:", error);
    throw error;
  }
  return location_name;
};

// Exits
export const queryExitsPerGame = async (gameId: bigint, playerLocationInst: bigint, playerInst: bigint): Promise<ExitInfo[] | undefined> => {
  let exits: ExitInfo[] = [];
  let exitEntity: Partial<Entity> | undefined;
  let exit: Partial<Exit> | undefined;
  let exitLeadsTo: Partial<Entity> | undefined;
  let counter = 0;
  
  
  try {
    
    // Query the lore-ParentToChildren model
    // const parentToChildren =  await queryParentToChildren(playerLocationInst);
    // console.log("DEBUG: queryExitsPerGame() parentToChildren: ", parentToChildren);
    // // Query the Game Instance Map
    // const game_inst_map = await queryGameInstaceMapByPlayer(gameId, playerInst);
    // console.log("DEBUG: queryExitsPerGame() game_inst_map: ", game_inst_map);
    
    // // Check if the parent has an exit
    // const parentInst = BigInt(parentToChildren?.inst.toString());
    // console.log("DEBUG: queryExitsPerGame() parentInst: ", parentInst);
    // // exit = await queryExitGIMap(game_inst_map, parentInst);
    // // if (exit) {
    // //   // Query the exit's entity model
    // //   exitEntity = await queryEntityGIMap(game_inst_map, parentInst);
    // //   console.log("DEBUG: queryExitsPerGame() exitEntity: ", exitEntity);
    // //   // Query the exit's leads_to entity model
    // //   const leads_to_inst = BigInt(exit.leads_to.toString());
    // //   exitLeadsTo = await queryEntityGIMap(game_inst_map, leads_to_inst);
    // //   console.log("DEBUG: queryExitsPerGame() exitLeadsTo: ", exitLeadsTo);
    // //   // Build the exitInfo object and add it to exits array
    // //   exits.push({
    // //     id: counter++,
    // //     name: exitEntity?.name ?? "unknown",
    // //     direction: stringCairoEnum(exit.direction_type ?? "None"),
    // //     destination: exit.is_enterable ? (exitLeadsTo?.name ?? "unknown") : "Unknown",
    // //   });
    // // }

    // // if (parentToChildren?.children?.length) {
    // //   for ( const child of parentToChildren.children ) {
    // //     console.log("DEBUG: queryExitsPerGame() child: ", child);
    // //     const childInst = BigInt(child.toString());
    // //     // Query the exit using the Game Instance Map
        
    // //     exit = await queryExitGIMap(game_inst_map, childInst);
    // //     console.log("DEBUG: queryExitsPerGame() exit: ", exit)
    // //     if (exit) {
    // //       // Query the exit's entity model
    // //       const exitInst = BigInt(exit!.inst!.toString());
    // //       exitEntity = await queryEntityGIMap(game_inst_map, exitInst);
    // //       console.log("DEBUG: queryExitsPerGame() exitEntity: ", exitEntity);
    // //       if (exit.leads_to) {
    // //         // Query the exit's leads_to entity model
    // //         const leads_to_inst = BigInt(exit.leads_to.toString());
    // //         exitLeadsTo = await queryEntityGIMap(game_inst_map, leads_to_inst);
    // //         console.log("DEBUG: queryExitsPerGame() exitLeadsTo: ", exitLeadsTo);
    // //       }
    // //       // Build the exitInfo object and add it to exits array
    // //       exits.push({
    // //         id: counter++,
    // //         name: exitEntity?.name ?? "unknown",
    // //         direction: stringCairoEnum(exit.direction_type ?? "None"),
    // //         destination: exit.is_enterable ? (exitLeadsTo?.name ?? "unknown") : "Unknown",
    // //       });
    // //     }

    // //     const exit2 = await queryExit(childInst);
    // //     console.log("DEBUG: queryExitsPerGame() exit2: ", exit2)
    // //     if (exit2) {
    // //       // Query the exit's entity model
    // //       exitEntity = await queryEntity(childInst);
    // //       console.log("DEBUG: queryExitsPerGame() exitEntity: ", exitEntity);
    // //       // Query the exit's leads_to entity model
    // //       const leads_to_inst = BigInt(exit2.leads_to.toString());
    // //       exitLeadsTo = await queryEntity(leads_to_inst);
    // //       console.log("DEBUG: queryExitsPerGame() exitLeadsTo: ", exitLeadsTo);
    // //       // Build the exitInfo object and add it to exits array
    // //       exits.push({
    // //         id: counter++,
    // //         name: exitEntity?.name ?? "unknown",
    // //         direction: stringCairoEnum(exit2.direction_type ?? "None"),
    // //         destination: exit2.is_enterable ? (exitLeadsTo?.name ?? "unknown") : "Unknown",
    // //       });
    // //     }
    // //   }
    // // }

    // // 1. Query the lore-ParentToChildren model and get the one whose inst is equal to playerlocationInst
    // const locationEntity = await queryEntity(playerLocationInst);
    // console.log("DEBUG: queryExitsPerGame() locationEntity3: ", locationEntity);

    // const parentToChildren3 =  await queryParentToChildren(playerLocationInst);
    // console.log("DEBUG: queryExitsPerGame() parentToChildren3: ", parentToChildren3);

    // const game_inst_map3 = await queryGameInstaceMapByPlayer(gameId, playerInst);
    // console.log("DEBUG: queryExitsPerGame() game_inst_map3: ", game_inst_map3);

    // for ( const child of parentToChildren3.children ) {
    //   console.log("DEBUG: queryExitsPerGame() child3-1-1: ", child);
    //   const childInst = BigInt(child.toString());
    //   console.log("DEBUG: queryExitsPerGame() childInst: ", childInst);
      
    //   const childExit3 = await queryExit(childInst);
    //   console.log("DEBUG: queryExitsPerGame() childExit3-1-2: ", childExit3)
    //   if (childExit3) {
    //     const childEntity3 = await queryEntity(childInst);
    //     console.log("DEBUG: queryExitsPerGame() childEnity3-1-3: ", childEntity3);
    //   }


    //   const childExit4 = await queryExitGIMap(game_inst_map, childInst);
    //   console.log("DEBUG: queryExitsPerGame() childExit4: ", childExit4)
    //   if (childExit4) {
    //     const childEntity4 = await queryEntity(childInst);
    //     console.log("DEBUG: queryExitsPerGame() childEnity4-1: ", childEntity4);
    //   }
    // }

    // console.log("DEBUG: queryExitsPerGame() BREAK POINT");

    // query game instance map
    const game_inst_map2 = await queryGameInstaceMap(gameId, playerLocationInst);
    console.log("DEBUG: queryExitsPerGame() game_inst_map2: ", game_inst_map2);

    // query parent to children
    const parentToChildren2 =  await queryParentToChildrenGIMap(game_inst_map2, playerLocationInst);
    console.log("DEBUG: queryExitsPerGame() parentToChildren2: ", parentToChildren2);

    for ( const child of parentToChildren2.children ) {
      const childInst33 = BigInt(child.toString());
      // const exit33 = await queryExitGIMap(game_inst_map2, childInst33);
      // console.log("DEBUG: queryExitsPerGame() exit33: ", exit33)
      // if (exit33) {
      //   const exit33Inst = BigInt(exit33.inst.toString());
      //   const gameInstMap4 = await queryGameInstaceMap(gameId, exit33Inst);
      //   console.log("DEBUG: queryExitsPerGame() gameInstMap4: ", gameInstMap4);
      //   const exit33_2 = await queryExitGIMap(gameInstMap4, exit33Inst);
      //   console.log("DEBUG: queryExitsPerGame() exit33_2: ", exit33_2)
      //   const exit33_3 = await queryExit(exit33Inst);
      //   console.log("DEBUG: queryExitsPerGame() exit33_3: ", exit33_3)
      // }
      
      const exit34 = await queryExit(childInst33);
      console.log("DEBUG: queryExitsPerGame() exit34: ", exit34)
      
      if (exit34) {
        // if child is exit, then query the exit using the game instance map
        const exit34Inst = BigInt(exit34.inst.toString());
        const gameInstMap5 = await queryGameInstaceMap(gameId, exit34Inst);
        console.log("DEBUG: queryExitsPerGame() gameInstMap5: ", gameInstMap5);
        const exit34_2 = await queryExitGIMap(gameInstMap5, exit34Inst);
        console.log("DEBUG: queryExitsPerGame() exit34_2: ", exit34_2)
        if (exit34_2) {
          // If we have the exit component for the game instance,   
          const exit34Entiy = await queryEntity(childInst33);  
          console.log("DEBUG: queryExitsPerGame() exit34Entiy: ", exit34Entiy)    
          // query the exit's leads_to entity model
          const leads_to_inst = BigInt(exit34_2.leads_to.toString());
          exitLeadsTo = await queryEntityGIMap(gameInstMap5, leads_to_inst);
          console.log("DEBUG: queryExitsPerGame() exit34_2LeadsTo: ", exitLeadsTo);
          const exitLeadsTo2 = await queryEntity(leads_to_inst);
          console.log("DEBUG: queryExitsPerGame() exitLeadsTo2: ", exitLeadsTo2);
          // Build the exitInfo object and add it to exits array
          exits.push({
            id: counter++,
            name: exit34Entiy?.name ?? "unknown",
            direction: stringCairoEnum(exit34_2.direction_type ?? "None"),
            destination: exit34_2.is_enterable ? (exitLeadsTo2?.name ?? "unknown") : "Unknown",
          });
        }
      }
    }

    console.log("DEBUG: queryExitsPerGame() exits: ", exits);
  } catch (error) {
    console.error("Error fetching exits from Torii:", error);
    throw error;
  }
  return exits;
};

const queryParentToChildren = async ( playerLocationInst: bigint): Promise<Partial<ParentToChildren> | undefined> => {
  let parent_to_children: Partial<ParentToChildren> | undefined;
  
  try {
    // 1. Query the lore-ParentToChild model and get the one whose inst is equal to playerlocationInst
    const { sdk } = await InitDojo();
    const query_parent_children = new ToriiQueryBuilder<SchemaType>()
      .withCursor("")
      .withLimit(1000)
      .includeHashedKeys()
      .withClause(
        new ClauseBuilder<SchemaType>().keys(
          ["lore-ParentToChildren"],
          [bigintToAddress(playerLocationInst)]
        ).build()
      )
      .withEntityModels(["lore-ParentToChildren"]);
    const result_parent_children = await sdk.getEntities({ query: query_parent_children });
    console.log("DEBUG: queryExitsPerGame() result_parent_children: ", result_parent_children);
    
    const parent_children = result_parent_children.getItems().find((item) => {
      const instHex = item.models?.lore?.ParentToChildren?.inst;
      return instHex !== undefined && BigInt(instHex) === playerLocationInst;
    });
    console.log("DEBUG: queryExitsPerGame() parent_children: ", parent_children);
    if (!parent_children) {
      console.error("ERROR: queryParentToChildren() parent_children is undefined");
      return undefined;
    }
    parent_to_children = parent_children?.models?.lore?.ParentToChildren;
  } catch (error) {
    console.error("Error fetching parent_to_children from Torii:", error);
    throw error;
  }
  return parent_to_children;
};

const queryParentToChildrenGIMap = async (gameInst: bigint, objInst: bigint): Promise<Partial<ParentToChildren> | undefined> => {
  let parentToChildren: Partial<ParentToChildren> | undefined;
  try{
    const { sdk } = await InitDojo();
    const queryValue = gameInst != 0n ? gameInst : objInst;
    const query_parentToChildren = new ToriiQueryBuilder<SchemaType>()
      .withCursor("")
      .withLimit(1000)
      .includeHashedKeys()
      .withClause(
        new ClauseBuilder<SchemaType>().keys(
          ["lore-ParentToChildren"],
            [bigintToHex128(queryValue)]
        ).build()
      ).withEntityModels(["lore-ParentToChildren"]);

    const result_parentToChildrenn = await sdk.getEntities({ query: query_parentToChildren });
    console.log("DEBUG: queryObjExit() result_parentToChildrenn: ", result_parentToChildrenn);
    
    const parentToChildren_item = result_parentToChildrenn.getItems().at(0);
    console.log("DEBUG: queryObjExit() parentToChildren_item: ", parentToChildren_item);

    parentToChildren = parentToChildren_item?.models?.lore?.ParentToChildren;
  } catch (error) {
    console.error("Error fetching parent to children from Torii:", error);
    throw error;
  }
  return parentToChildren;
};

const queryExitGIMap = async (gameInst: bigint, objInst: bigint): Promise<Partial<Exit> | undefined> => {
  let child_exit: Partial<Exit> | undefined;
  const { sdk } = await InitDojo();
  const queryValue = gameInst != 0n ? gameInst : objInst;
  const query_obj_exit = new ToriiQueryBuilder<SchemaType>()
    .withCursor("")
    .withLimit(1000)
    .includeHashedKeys()
    .withClause(
      new ClauseBuilder<SchemaType>().keys(
        ["lore-Exit"],
        [bigintToHex128(queryValue)]
      ).build()
    ).withEntityModels(["lore-Exit"]);

  const result_obj_exit = await sdk.getEntities({ query: query_obj_exit });
  console.log("DEBUG: queryObjExit() result_obj_exitGIMap: ", result_obj_exit);
  
  const obj_exit_item = result_obj_exit.getItems().at(0);
  console.log("DEBUG: queryObjExit() obj_exit_itemGIMap: ", obj_exit_item);

  child_exit = obj_exit_item?.models?.lore?.Exit;
  return child_exit;
};

const queryEntityGIMap = async (gameInst: bigint, objInst: bigint): Promise<Partial<Entity> | undefined> => {
  let entity: Partial<Entity> | undefined;
  const { sdk } = await InitDojo();
  const queryValue = gameInst != 0n ? gameInst : objInst;
  const query_obj_entity = new ToriiQueryBuilder<SchemaType>()
    .withCursor("")
    .withLimit(1000)
    .includeHashedKeys()
    .withClause(
      new ClauseBuilder<SchemaType>().keys(
        ["lore-Entity"],
          [bigintToHex128(queryValue)]
      ).build()
    )
    .withEntityModels(["lore-Entity"]);
  const result_obj_entity = await sdk.getEntities({ query: query_obj_entity });
  console.log("DEBUG: queryObjEntity() result_obj_entityGIMap: ", result_obj_entity);
  
  const obj_entity_item = result_obj_entity.getItems().at(0);
  console.log("DEBUG: queryObjEntity() obj_entity_itemGIMap: ", obj_entity_item);

  entity = obj_entity_item?.models?.lore?.Entity;
  return entity;
};

const queryEntity = async (inst: bigint): Promise<Partial<Entity> | undefined> => {
  let entity: Partial<Entity> | undefined;
  const { sdk } = await InitDojo();
  const query_entity = new ToriiQueryBuilder<SchemaType>()
    .withCursor("")
    .withLimit(1000)
    .includeHashedKeys()
    .withClause(
      new ClauseBuilder<SchemaType>().keys(
        ["lore-Entity"],
        [bigintToHex128(inst)]
      ).build()
    )
    .withEntityModels(["lore-Entity"]);
  const result_entity = await sdk.getEntities({ query: query_entity });
  console.log("DEBUG: queryEntity() result_entity: ", result_entity);
  
  const entity_item = result_entity.getItems().find((item) => {
    const instHex = item.models?.lore?.Entity?.inst;
    console.log("DEBUG: queryEntity() instHex: ", instHex);
    console.log("DEBUG: queryEntity() inst: ", inst);
    return instHex !== undefined && BigInt(instHex) === inst;
  });
  console.log("DEBUG: queryEntity() entity_item: ", entity_item);
  // if (!entity_item) {
  //   console.error("ERROR: queryEntity() entity_item is undefined");
  //   return undefined;
  // }
  entity = entity_item?.models?.lore?.Entity;
  return entity;
};

const queryExit = async (inst: bigint): Promise<Partial<Exit> | undefined> => {
  let exit: Partial<Exit> | undefined;
  const { sdk } = await InitDojo();
  const query_exit = new ToriiQueryBuilder<SchemaType>()
    .withCursor("")
    .withLimit(1000)
    .includeHashedKeys()
    .withClause(
      new ClauseBuilder<SchemaType>().keys(
        ["lore-Exit"],
        [bigintToHex128(inst)]
      ).build()
    )
    .withEntityModels(["lore-Exit"]);
  const result_exit = await sdk.getEntities({ query: query_exit });
  console.log("DEBUG: queryExit() result_exit: ", result_exit);
  
  const exit_item = result_exit.getItems().find((item) => {
    const instHex = item.models?.lore?.Exit?.inst;
    return instHex !== undefined && BigInt(instHex) === inst;
  });
  console.log("DEBUG: queryExit() exit_item: ", exit_item);
  
  exit = exit_item?.models?.lore?.Exit;
  return exit;
};

export const queryGameInstaceMap = async (gameId: bigint, inst: bigint): Promise<bigint> => {
  let game_inst_map: bigint = 0n;
  try{
    const { sdk } = await InitDojo();
    // Get the game instance using the location entity and the game id
    const query_location_game_inst = new ToriiQueryBuilder<SchemaType>()
      .withCursor("")
      .withLimit(1000)
      .includeHashedKeys()
      .withClause(
        new ClauseBuilder<SchemaType>().keys(
          ["lore-GameInstanceMap"],
          [bigintToHex128(gameId), bigintToAddress(inst)]
        ).build()
      ).withEntityModels(["lore-GameInstanceMap"]);
    
    const result_location_game_inst = await sdk.getEntities({ query: query_location_game_inst });
    console.log("DEBUG: queryGameInstaceMap() result_location_game_inst: ", result_location_game_inst);

    game_inst_map = BigInt(result_location_game_inst.getItems().at(0)?.models?.lore?.GameInstanceMap?.game_inst ?? 0);
    
    
  } catch (error) {
    console.error("Error fetching game instance map from Torii:", error);
    throw error;
  }
  return game_inst_map; 
};
