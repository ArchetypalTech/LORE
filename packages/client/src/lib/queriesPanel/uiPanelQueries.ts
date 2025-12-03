import { getPlayerAddress } from "../../editor/lib/components";
import { InitDojo } from "../dojo";
import { ToriiQueryBuilder } from "@dojoengine/sdk";
import { SchemaType } from "@/lib/dojo_bindings/typescript/models.gen";
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
    console.log("DEBUG: queryPlayerLocationPerGame() playerInst: ", playerInst);
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
    console.log("DEBUG: queryPlayerLocationPerGame() result_player_game_inst: ", result_player_game_inst);

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
    // get invItem
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
export const queryExitsPerGame = async (gameId: bigint, playerLocationInst: bigint): Promise<ExitInfo[]> => {
  let exits: ExitInfo[] = [];
  
  try {
    // 1. Query the lore-ParentToChild model and get the one whose inst is equal to playerlocationInst
    // const { sdk } = await InitDojo();
    // const query_parent_child = new ToriiQueryBuilder<SchemaType>()
    //   .withCursor("")
    //   .withLimit(1000)
    //   .includeHashedKeys()
    //   .withClause(
    //     new ClauseBuilder<SchemaType>().keys(
    //       ["lore-ParentToChild"],
    //       [bigintToHex128(gameId), bigintToAddress(playerLocationInst)]
    //     ).build()
    //   )
    //   .withEntityModels(["lore-ParentToChild"]);
    // const result_parent_child = await sdk.getEntities({ query: query_parent_child });
    // console.log("DEBUG: queryExitsPerGame() result_parent_child: ", result_parent_child);
    
    // const parent_child = result_parent_child.getItems().find((item) => {
    //   return item.models?.lore?.ParentToChild?.inst === playerLocationInst;
    // });
    // console.log("DEBUG: queryExitsPerGame() parent_child: ", parent_child);


    // 1. Query the lore-ParentChild model using the GIMap and the player location entity
    const { sdk } = await InitDojo();
    const query_parent_child = new ToriiQueryBuilder<SchemaType>()
      .withCursor("")
      .withLimit(1000)
      .includeHashedKeys()
      .withClause(
        new ClauseBuilder<SchemaType>().keys(
          ["lore-ParentToChild"],
          [bigintToHex128(gameId), bigintToAddress(playerLocationInst)]
        ).build()
      )
      .withEntityModels(["lore-ParentToChild"]);
    const result_parent_child = await sdk.getEntities({ query: query_parent_child });
    console.log("DEBUG: queryExitsPerGame() result_parent_child: ", result_parent_child);
    
    const parent_child = result_parent_child.getItems().find((item) => {
      return item.models?.lore?.ParentToChildren?.inst === playerLocationInst;
    });
    console.log("DEBUG: queryExitsPerGame() parent_child: ", parent_child);

    // for each child, query the lore-Exit model
    if (parent_child?.models?.lore?.ParentToChildren?.children.length > 0) {
      const children = parent_child?.models?.lore?.ParentToChildren?.children;
      let counter = 0;
      for (const child of children) {
        let  entity_name: string = "";
        let leads_to_entity_name: string = "";
        const { sdk } = await InitDojo();
        const query_exit = new ToriiQueryBuilder<SchemaType>()
          .withCursor("")
          .withLimit(1000)
          .includeHashedKeys()
          .withClause(
            new ClauseBuilder<SchemaType>().keys(
              ["lore-Exit"],
              [bigintToHex128(gameId), bigintToAddress(child)]
            ).build()
          )
          .withEntityModels(["lore-Exit"]);
        const result_exit = await sdk.getEntities({ query: query_exit });
        console.log("DEBUG: queryExitsPerGame() result_exit: ", result_exit);
        
        const exit = result_exit.getItems().find((item) => {
          return item.models?.lore?.Exit?.inst === child;
        });
        console.log("DEBUG: queryExitsPerGame() exit: ", exit);

        if (exit) {
          try {
            // query exit name
            const { sdk } = await InitDojo();
            const query_name = new ToriiQueryBuilder<SchemaType>()
              .withCursor("")
              .withLimit(1000)
              .includeHashedKeys()
              .withClause(
                new ClauseBuilder<SchemaType>().keys(
                  ["lore-Entity"],
                  [bigintToHex128(gameId), bigintToAddress(exit?.models?.lore?.Exit?.inst ?? 0)]
                ).build()
              )
              .withEntityModels(["lore-Entity"]);
            const result_name = await sdk.getEntities({ query: query_name });
            console.log("DEBUG: queryExitsPerGame() result_name: ", result_name);
            
            const exit_name = result_name.getItems().find((item) => {
              return item.models?.lore?.Entity?.inst === exit?.models?.lore?.Exit?.inst;
            });
            entity_name = exit_name?.models?.lore?.Entity?.name ?? "unknown";
            console.log("DEBUG: queryExitsPerGame() entity_name: ", entity_name);
          } catch (error) {
            console.error("Error fetching exit name from Torii:", error);
            throw error;
          }
          
          try {
            // query leads_to entity name
            const { sdk } = await InitDojo();
            const query_leads_to = new ToriiQueryBuilder<SchemaType>()
              .withCursor("")
              .withLimit(1000)
              .includeHashedKeys()
              .withClause(
                new ClauseBuilder<SchemaType>().keys(
                  ["lore-Entity"],
                  [bigintToHex128(gameId), bigintToAddress(exit?.models?.lore?.Exit?.leads_to ?? 0)]
                ).build()
              )
              .withEntityModels(["lore-Entity"]);
            const result_leads_to = await sdk.getEntities({ query: query_leads_to });
            console.log("DEBUG: queryExitsPerGame() result_leads_to: ", result_leads_to);
            
            const leads_to_entity = result_leads_to.getItems().find((item) => {
              return item.models?.lore?.Entity?.inst === exit?.models?.lore?.Exit?.leads_to;
            });
            leads_to_entity_name = leads_to_entity?.models?.lore?.Entity?.name ?? "unknown";
            console.log("DEBUG: queryExitsPerGame() leads_to: ", leads_to_entity);
          } catch (error) {
            console.error("Error fetching leads_to entity name from Torii:", error);
            throw error;
          }
          
          // add exit to exits array
          exits.push({
            id: counter,
            name: entity_name,
            direction: stringCairoEnum(exit?.models?.lore?.Exit?.direction_type ?? "None"),
            destination: leads_to_entity_name,
            is_enterable: exit?.models?.lore?.Exit?.is_enterable ?? false,
          });

          // increase counter
          counter++;
        }
      }
    } 
  } catch (error) {
    console.error("Error fetching exits from Torii:", error);
    throw error;
  }
  return exits;
};