import { getPlayerAddress } from "../../editor/lib/components";
import { InitDojo } from "../dojo";
import { ToriiQueryBuilder } from "@dojoengine/sdk";
import { SchemaType, ParentToChildren, Entity, Exit, Action, ActionExecuted } from "@/lib/dojo_bindings/typescript/models.gen";
import { ClauseBuilder } from "@dojoengine/sdk";
import { bigintToAddress, bigintToHex128 } from "@/lib/utils/utils";
import { ExitInfo, PuzzleInfo } from "../stores/terminal.uiPanel.store";
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
  console.log("\n[PLE] Query PlayerLocationEntityGIMap");
  console.log("[PLE] gameInst:", gameInst.toString(), "origInst:", origInst.toString());
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
export const queryExitsPerGame = async (
  gameId: bigint,
  playerLocationInst: bigint,
): Promise<ExitInfo[] | undefined> => {
  let exits: ExitInfo[] = [];
  let counter = 0;

  try {
    console.log("\n=== [Exits] START QUERY ===");
    console.log("PlayerLocationInst:", playerLocationInst.toString());

    // ---------------------------------------------------------
    // 1. Resolve GameInstanceMap for the player's LOCATION
    // ---------------------------------------------------------
    const locationGameInst = await queryGameInstaceMap(gameId, playerLocationInst);
    console.log("[Exits] Location GameInst:", locationGameInst.toString());

    // ---------------------------------------------------------
    // 2. Query ParentToChildren using GIMap(location)
    // ---------------------------------------------------------
    const parentToChildren = await queryParentToChildrenGIMap(locationGameInst, playerLocationInst);
    console.log("[Exits] ParentToChildren:", parentToChildren);

    if (!parentToChildren || !parentToChildren.children) {
      console.log("[Exits] No children found.");
      return exits;
    }

    // ---------------------------------------------------------
    // 3. Loop through children of the location
    // ---------------------------------------------------------
    for (const child of parentToChildren.children) {
      const childInst = BigInt(child.toString());
      console.log("\n[Exits] Checking child:", childInst.toString());

      // -----------------------------------------------------
      // 3.1 Get the exitChild from GIMap
      //  This is for the exit status per game
      // -----------------------------------------------------
      const childGameInst = await queryGameInstaceMap(gameId, childInst);
      console.log("[Exits] Child GameInst:", childGameInst.toString());

      // -----------------------------------------------------
      // 3.2 Find Exit component via GIMap
      // -----------------------------------------------------
      const childExit =  await queryExitGIMap(childGameInst, childInst);
      console.log("[Exits] Child Exit:", childExit);
      if (!childExit) {
        console.log("[Exits] ChildExit not in queryGIMAP");

        // 3.2.1 Find Exit via Query
        const childExit2 =  await queryExit(childInst);
        console.log("[Exits] ChildExit 2:", childExit2);
        if (!childExit2) {
          console.log("[Exits] ChildExit 2 not in query");
          continue;
        }
        console.log("[Exits] ChildExit 2 in query");
        
        // 3.2.2 Get the exit ENTITY (static name)
        const exitEntity =  await queryEntity(childInst);
        console.log("[Exits] Exit 2 Entity (base inst):", exitEntity);

        // 3.2.3 Resolve leads_to 
        const leads_to_inst = BigInt(childExit2.leads_to.toString());
        console.log("[Exits] leads_to inst 2:", leads_to_inst.toString());

        const leads_to_entity = await queryEntity(leads_to_inst);
        console.log("[Exits] leads_to Entity 2:", leads_to_entity);

        exits.push({
          id: counter++,
          name: exitEntity?.name ?? "unknown exit",
          direction: stringCairoEnum(childExit2.direction_type ?? "None"),
          destination: childExit2.is_enterable
            ? (leads_to_entity?.name ?? "unknown location")
            : "Unknown"
        });
        continue;
      }
      console.log("[Exits] Child IS an exit!");

      // -----------------------------------------------------
      // 3.3 Get the exit Entity (static name)
      // -----------------------------------------------------
      const exitEntity =  await queryEntity(childInst);
      console.log("[Exits] Exit Entity (base inst):", exitEntity);

      // -----------------------------------------------------
      // 3.4 Get the leads_to entity
      // -----------------------------------------------------
      const leads_to_inst = BigInt(childExit.leads_to.toString());
      console.log("[Exits] leads_to inst:", leads_to_inst.toString());

      const leads_to_entity = await queryEntity(leads_to_inst);
      console.log("[Exits] leads_to Entity:", leads_to_entity);

      exits.push({
        id: counter++,
        name: exitEntity?.name ?? "unknown exit",
        direction: stringCairoEnum(childExit.direction_type ?? "None"),
        destination: childExit.is_enterable
          ? (leads_to_entity?.name ?? "unknown location")
          : "Unknown"
      });
    }

    console.log("\n=== [Exits] DONE ===");
    console.log("Collected exits:", exits);

  } catch (error) {
    console.error("Error fetching exits from Torii:", error);
    throw error;
  }

  return exits;
};

const queryParentToChildrenGIMap = async (
  gameInst: bigint,
  objInst: bigint
): Promise<Partial<ParentToChildren> | undefined> => {
  let parentToChildren: Partial<ParentToChildren> | undefined;
  console.log("\n[PTC] Query ParentToChildren");
  console.log("[PTC] gameInst:", gameInst.toString(), "objInst:", objInst.toString());
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

    const result = await sdk.getEntities({ query: query_parentToChildren });
    console.log("[PTC]: query result: ", result);
    
    const item = result.getItems().at(0);
    console.log("[PTC]: Item: ", item);

    parentToChildren = item?.models?.lore?.ParentToChildren;
  } catch (error) {
    console.error("Error fetching parent to children from Torii:", error);
    throw error;
  }
  return parentToChildren;
};

const queryExitGIMap = async (
  gameInst: bigint,
  objInst: bigint
): Promise<Partial<Exit> | undefined> => {
  let exit: Partial<Exit> | undefined;
  console.log("\n[ExitGIMap] Query Exit");
  console.log("[ExitGIMap] gameInst:", gameInst.toString(), "objInst:", objInst.toString());
  try {
    const { sdk } = await InitDojo();
    const queryValue = gameInst != 0n ? gameInst : objInst;

    const query_exit = new ToriiQueryBuilder<SchemaType>()
      .withCursor("")
      .withLimit(1000)
      .includeHashedKeys()
      .withClause(
        new ClauseBuilder<SchemaType>().keys(
          ["lore-Exit"],
          [bigintToHex128(queryValue)]
        ).build()
      ).withEntityModels(["lore-Exit"]);

    const result = await sdk.getEntities({ query: query_exit });
    console.log("[ExitGIMap] Result:", result);

    const item = result.getItems().at(0);
    console.log("[ExitGIMap] Item:", item);
    exit = item?.models?.lore?.Exit;
    console.log("[ExitGIMap] exit:", exit);
  } catch (error) {
    console.error("Error fetching exit from Torii:", error);
    throw error;
  }

  return exit;
};

export const queryGameInstaceMap = async (gameId: bigint, inst: bigint): Promise<bigint> => {
  let game_inst_map: bigint = 0n;
  try{
    const { sdk } = await InitDojo();
    // Get the game instance using the coins entity and the game id
    const query_game_inst = new ToriiQueryBuilder<SchemaType>()
      .withCursor("")
      .withLimit(1000)
      .includeHashedKeys()
      .withClause(
        new ClauseBuilder<SchemaType>().keys(
          ["lore-GameInstanceMap"],
          [bigintToHex128(gameId), bigintToAddress(inst)]
        ).build()
      ).withEntityModels(["lore-GameInstanceMap"]);
    
    const result_game_inst = await sdk.getEntities({ query: query_game_inst });
    console.log("DEBUG: queryGameInstaceMap() result_game_inst: ", result_game_inst);

    game_inst_map = BigInt(result_game_inst.getItems().at(0)?.models?.lore?.GameInstanceMap?.game_inst ?? 0);
    
  } catch (error) {
    console.error("Error fetching game instance map from Torii:", error);
    throw error;
  }
  return game_inst_map; 
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

// Puzzles
export const queryPuzzlesPerGame = async (
  gameId: bigint,
  playerLocationInst: bigint,
): Promise<PuzzleInfo[] | undefined> => {
  let puzzles: PuzzleInfo[] = [];

  try {
    console.log("\n=== [Puzzles] START QUERY ===");
    console.log("PlayerLocationInst:", playerLocationInst.toString());

    // ---------------------------------------------------------
    // 1. Resolve GameInstanceMap for the player's LOCATION
    // ---------------------------------------------------------
    const locationGameInst = await queryGameInstaceMap(gameId, playerLocationInst);
    console.log("[Puzzles] Location GameInst:", locationGameInst.toString());

    // ---------------------------------------------------------
    // 2. Query Location Entity
    // ---------------------------------------------------------
    const locationEntity = await queryEntityGIMap(locationGameInst, playerLocationInst);
    console.log("[Puzzles] Location Entity:", locationEntity);

    const locationEntity2 = await queryEntity(playerLocationInst);
    console.log("[Puzzles] Location Entity 2:", locationEntity2);

    // ---------------------------------------------------------
    // Get Actions ID's from entity
    // ---------------------------------------------------------
    const actions = locationEntity?.actions_keys ?? [];
    console.log("[Puzzles] Actions:", actions);

    const actions2 = locationEntity2?.actions_keys ?? [];
    console.log("[Puzzles] Actions 2:", actions2);

    for (const action of actions) {
      const actionKey = BigInt(action.toString());
      console.log("\n[Puzzles] Checking action:", actionKey.toString());

      // -----------------------------------------------------
      // 3.1 Query Original Action for static name
      // -----------------------------------------------------
      const actionEntity = await queryAction(locationEntity?.inst, actionKey);
      console.log("[Puzzles] Action Entity:", actionEntity);

      const actionEntity2 = await queryAction(locationEntity2?.inst, actionKey);
      console.log("[Puzzles] Action Entity 2:", actionEntity2);

      const actionName1 = actionEntity?.name ?? "unknown";
      const actionName2 = actionEntity2?.name ?? "unknown2";
      console.log("[Puzzles] Action Name:", actionName1);
      console.log("[Puzzles] Action Name 2:", actionName2);

      // -----------------------------------------------------
      // 3.2 Query the action executed
      // -----------------------------------------------------
      const actionStatus = await queryActionExecuted(locationEntity?.inst, actionKey);
      console.log("[Puzzles] Action Status:", actionStatus);
      const actionStatus2 = await queryActionExecuted(locationEntity2?.inst, actionKey);
      console.log("[Puzzles] Action Status 2:", actionStatus2);

      if (!actionStatus) {
        console.log("[Puzzles] Action has not been registered yet.");
        continue;
      }

      // -----------------------------------------------------
      // 3.3 Build the puzzle object and add it to puzzles array
      // -----------------------------------------------------
      puzzles.push({
        name: actionName1,
        executed: actionStatus.is_executed,
      });
    }

    console.log("\n=== [Puzzles] DONE ===");
    console.log("Collected puzzles:", puzzles);
  } catch (error) {
    console.error("Error fetching puzzles from Torii:", error);
    throw error;
  }
  return puzzles;
};

const queryAction = async (inst: bigint, key: bigint): Promise<Partial<Action> | undefined> => {
  let action: Partial<Action> | undefined;
  try { 
    const { sdk } = await InitDojo();
    const query_action = new ToriiQueryBuilder<SchemaType>()
      .withCursor("")
      .withLimit(1000)
      .includeHashedKeys()
      .withClause(
        new ClauseBuilder<SchemaType>().keys(
          ["lore-Action"],
          [bigintToHex128(key), bigintToAddress(inst)]
        ).build()
      )
      .withEntityModels(["lore-Action"]);
    const result_action = await sdk.getEntities({ query: query_action });
    console.log("DEBUG: queryAction() result_action: ", result_action);
    
    const action_item = result_action.getItems().at(0);
    console.log("DEBUG: queryAction() action_item: ", action_item);
    action = action_item?.models?.lore?.Action;
  } catch (error) {
    console.error("Error fetching action from Torii:", error);
    throw error;
  }
  return action;
};

const queryActionExecuted = async (inst: bigint, key: bigint): Promise<Partial<ActionExecuted> | undefined> => {
  let actionExecuted: Partial<ActionExecuted> | undefined;
  try { 
    const { sdk } = await InitDojo();
    const query_action = new ToriiQueryBuilder<SchemaType>()
      .withCursor("")
      .withLimit(1000)
      .includeHashedKeys()
      .withClause(
        new ClauseBuilder<SchemaType>().keys(
          ["lore-ActionExecuted"],
          [bigintToHex128(key), bigintToAddress(inst)]
        ).build()
      )
      .withEntityModels(["lore-ActionExecuted"]);
    const result_action = await sdk.getEntities({ query: query_action });
    console.log("DEBUG: queryActionExecuted() result_action: ", result_action);
    
    const action_item = result_action.getItems().at(0);
    console.log("DEBUG: queryActionExecuted() action_item: ", action_item);
    actionExecuted = action_item?.models?.lore?.ActionExecuted;
  } catch (error) {
    console.error("Error fetching action executed from Torii:", error);
    throw error;
  }
  return actionExecuted;
};


