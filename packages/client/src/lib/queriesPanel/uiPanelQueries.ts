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
export const queryPlayerLocationPerGame = async (gameId: bigint): Promise<[(string | undefined), (bigint| undefined)]> => {
  // console.log("DEBUG: queryPlayerLocationPerGame() gameId: ", gameId);
  let player_location: string | undefined;
  let location_inst: bigint | undefined;
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

    const playerInst = BigInt(player?.models?.lore?.Player?.inst ?? 0);
    // console.log("DEBUG: queryPlayerLocationPerGame() playerInst: ", playerInst);
    if (!playerInst) {
      console.error("ERROR: queryPlayerLocationPerGame() playerInst is undefined");
      return ([undefined, undefined]);
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
  return ([player_location, location_inst]);
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
export const queryExitsPerGame = async (gameId: bigint, playerLocationInst: bigint): Promise<ExitInfo[] | undefined> => {
  let exits: ExitInfo[] = [];
  let counter = 0;
  
  try {
    // 1. Query the lore-ParentToChildren model and get the one whose inst is equal to playerlocationInst
    const parentToChildren =  await queryParentToChildren(playerLocationInst);
    console.log("DEBUG: queryExitsPerGame() parentToChildren: ", parentToChildren);

    
    let exitEntity: Partial<Entity> | undefined;
    let exit: Partial<Exit> | undefined;
    let exitLeadsTo: Partial<Entity> | undefined;

    // 2. For the parent, check it it has an exit
    const parentInst = BigInt(parentToChildren?.inst.toString());
    console.log("DEBUG: queryExitsPerGame() parentInst: ", parentInst);
    const gameInstMap = await queryGameInstaceMapByPlayer(gameId, parentInst);
    console.log("DEBUG: queryExitsPerGame() gameInstMap: ", gameInstMap);
    exit = await queryExitGIMap(gameInstMap, parentInst);
    console.log("DEBUG: queryExitsPerGame() exit: ", exit);
    if (exit) {
      console.log("DEBUG: queryExitsPerGame() exitParent: ", exit);
      // Query the exit's entity model
      exitEntity = await queryEntity(parentInst);
      console.log("DEBUG: queryExitsPerGame() exitEntity: ", exitEntity);
      // Query the exit's leads_to entity model
      const leadsToInst = BigInt(exit.leads_to.toString());
      exitLeadsTo = await queryEntity(leadsToInst);
      console.log("DEBUG: queryExitsPerGame() exitLeadsTo: ", exitLeadsTo);
      // build the exitInfo object and add it to exits array
      exits.push({
        id: counter++,
        name: exitEntity?.name ?? "unknown",
        direction: stringCairoEnum(exit.direction_type ?? "None"),
        destination: exit.is_enterable ? (exitLeadsTo?.name ?? "unknown") : "Unknown",
      });
    }

    // 3. For each child, query the lore-Entity and lore-Exit models
    if (parentToChildren?.children?.length) {
      for (const child of parentToChildren.children) {
        const childBigInt = BigInt(child.toString());
        console.log("DEBUG: queryExitsPerGame() childBigInt: ", childBigInt);
        const gameInstMap = await queryGameInstaceMapByPlayer(gameId, childBigInt);
        console.log("DEBUG: queryExitsPerGame() gameInstMap: ", gameInstMap);
        exit = await queryExitGIMap(gameInstMap, childBigInt);
        console.log("DEBUG: queryExitsPerGame() exit: ", exit);
        // If the child is an exit, 
        if (exit) {
          // Query the exit's entity model
          exitEntity = await queryEntity(childBigInt);
          console.log("DEBUG: queryExitsPerGame() exitEntityChild: ", exitEntity);
          // Query the exit's leads_to entity model
          const leadsToInst = BigInt(exit.leads_to.toString());
          exitLeadsTo = await queryEntity(leadsToInst);
          console.log("DEBUG: queryExitsPerGame() exitChildLeadsTo: ", exitLeadsTo);
          // build the exitInfo object and add it to exits array
        
          exits.push({
            id: counter++,
            name: exitEntity?.name ?? "unknown",
            direction: stringCairoEnum(exit.direction_type ?? "None"),
            destination: exit.is_enterable ? (exitLeadsTo?.name ?? "unknown") : "Unknown",
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

const queryExitGIMap = async (gameInst: bigint, objInst: bigint): Promise<Partial<Exit> | undefined> => {
  let child_exit: Partial<Exit> | undefined;
  const { sdk } = await InitDojo();
  const queryValue = gameInst != 0n ? gameInst : objInst;
  console.log("DEBUG: queryExitGIMap() gameInst: ", gameInst);
  console.log("DEBUG: queryExitGIMap() objInst: ", objInst);
  console.log("DEBUG: queryExitGIMap() queryValue: ", queryValue);
  const query_obj_exit = new ToriiQueryBuilder<SchemaType>()
    .withCursor("")
    .withLimit(1000)
    .includeHashedKeys()
    .withClause(
      new ClauseBuilder<SchemaType>().keys(
        ["lore-Exit"],
          [bigintToHex128(queryValue)]
      ).build()
    )
    .withEntityModels(["lore-Exit"]);
  const result_obj_exit = await sdk.getEntities({ query: query_obj_exit });
  console.log("DEBUG: queryObjExit() result_child_exit: ", result_obj_exit);
  
  const obj_exit_item = result_obj_exit.getItems().at(0);
  console.log("DEBUG: queryObjExit() obj_exit_item: ", obj_exit_item);

  child_exit = obj_exit_item?.models?.lore?.Exit;
  return child_exit;
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