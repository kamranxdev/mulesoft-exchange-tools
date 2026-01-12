#!/usr/bin/env python3

# Exchange Asset Dependency "Ghost Hunter"
# Identifies assets in MuleSoft Exchange that have zero consumers (Orphans).
# Helps in cleaning up unused fragments, examples, and connectors.

import argparse
import requests
import json
import sys

def get_token(username, password):
    url = "https://anypoint.mulesoft.com/accounts/login"
    payload = {"username": username, "password": password}
    response = requests.post(url, json=payload)
    response.raise_for_status()
    return response.json()["access_token"]

def get_all_assets(token, org_id):
    url = "https://anypoint.mulesoft.com/exchange/api/v2/assets"
    headers = {"Authorization": f"Bearer {token}", "X-ANYPNT-ORG-ID": org_id}
    
    assets = []
    offset = 0
    limit = 100
    
    print("Scanning Exchange for assets...")
    while True:
        params = {"offset": offset, "limit": limit, "masterOrganizationId": org_id}
        response = requests.get(url, headers=headers, params=params)
        response.raise_for_status()
        data = response.json()
        
        batch = data if isinstance(data, list) else data.get("results", [])
        if not batch:
            break
            
        assets.extend(batch)
        offset += limit
        print(f"  Fetched {len(assets)} assets so far...")
    
    return assets

def get_asset_dependencies(token, org_id, group_id, asset_id, version):
    # This endpoint fetches dependencies for a specific asset version
    # Note: Exchange API structure for dependencies varies. 
    # This is a simplified implementation checking 'dependencies' key in POM or metadata.
    # For a robust check, one might need to download the POM or use Graph API.
    # Here we check the standard response metadata.
    
    # In V2 API, dependencies are often not in the list view. 
    # Validating EVERY asset detail is slow. 
    # We will assume the 'dependencies' list is present in the asset detail.
    
    url = f"https://anypoint.mulesoft.com/exchange/api/v2/assets/{group_id}/{asset_id}/{version}"
    headers = {"Authorization": f"Bearer {token}", "X-ANYPNT-ORG-ID": org_id}
    
    try:
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            data = response.json()
            return data.get("dependencies", [])
    except:
        pass
    return []

def main():
    parser = argparse.ArgumentParser(description="Find Orphaned Exchange Assets")
    parser.add_argument("--username", required=True, help="MuleSoft Username")
    parser.add_argument("--password", required=True, help="MuleSoft Password")
    parser.add_argument("--org_id", required=True, help="Organization ID")
    parser.add_argument("--output", default="orphaned_assets.json", help="Output file")
    
    args = parser.parse_args()
    
    try:
        token = get_token(args.username, args.password)
        print("Authentication successful.")
        
        all_assets = get_all_assets(token, args.org_id)
        
        # Build Map of All Assets: { "group:asset:version": AssetData }
        asset_map = {}
        for asset in all_assets:
            key = f"{asset['groupId']}:{asset['assetId']}:{asset['version']}"
            asset_map[key] = asset
        
        print(f"Total Assets found: {len(asset_map)}")
        
        # Build Set of USED Assets
        used_assets = set()
        
        print("Analyzing dependencies (this may take time)...")
        # For this PoC, we only process the first 50 assets to avoid hitting rate limits in a script demo.
        # In production, remove [:50]
        for i, asset in enumerate(all_assets[:50]):
             # We need to fetch details to see dependencies
            deps = get_asset_dependencies(token, args.org_id, asset['groupId'], asset['assetId'], asset['version'])
            
            for dep in deps:
                # Dependency format usually: { groupId, assetId, version }
                dep_key = f"{dep.get('groupId')}:{dep.get('assetId')}:{dep.get('version')}"
                used_assets.add(dep_key)
                
            if i % 10 == 0:
                print(f"  Analyzed {i} assets...")

        # Find Orphans
        orphans = []
        for key, asset in asset_map.items():
            # If an asset is NOT in used_assets, it MIGHT be an orphan.
            # Caution: Top-level APIs won't be in 'used_assets' because nothing depends ON them (usually).
            # So we typically filter for Fragments/Connectors which SHOULD be used.
            
            if key not in used_assets:
                asset_type = asset.get("type", "unknown")
                if asset_type in ["raml-fragment", "oas-component", "custom-connector"]:
                    orphans.append(asset)

        print(f"Found {len(orphans)} potential orphaned fragments/connectors.")
        
        with open(args.output, "w") as f:
            json.dump(orphans, f, indent=2)
            
        print(f"Report saved to {args.output}")

    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
