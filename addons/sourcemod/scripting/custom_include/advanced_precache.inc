// https://forums.alliedmods.net/showthread.php?t=309382&highlight=precache

#if defined _advanced_precache_included
	#endinput
#endif
#define _advanced_precache_included

#include <emitsoundany>

stock int StrExtract(char[] sBuffer, const char[] sSource, int startPos, int endPos) {
    // Calculate string length. Also add space for null terminator
    int iMaxLen = endPos - startPos + 1;
    
    // Validate length
    if(iMaxLen < 0)
    {
        sBuffer[0] = '\0';
        return 0;
    }
    
    // Extract string and store it in the buffer
    return strcopy(sBuffer, iMaxLen, sSource[startPos]);
}

/**
 * Precache models and return model index.
 *  NOTE: Precache with engine 'hide' models included.
 *
 * @param sModel            The model path.
 * @return                  The model index if was precached, 0 otherwise.
 **/
stock int ModelsPrecacheStatic(const char[] sModel)
{
    // If model path is empty, then stop
    if(!strlen(sModel))
    {
        return 0;
    }
    
    // If model didn't exist, then
    if(!FileExists(sModel))
    {
        // Try to find model in game folder by name
        return ModelsPrecacheStandart(sModel);
    }
    
    // If model doesn't precache yet, then continue
    if(!IsModelPrecached(sModel))
    {
        // Precache model materails
        ModelsPrecacheMaterials(sModel);

        // Precache model resources
        ModelsPrecacheResources(sModel);
    }
    
    // Return on the success
    return PrecacheModel(sModel, true);
}

/**
 * Precache weapon models and return model index.
 *
 * @param sModel            The model path. 
 * @return                  The model index if was precached, 0 otherwise.
 **/
stock int ModelsPrecacheWeapon(const char[] sModel)
{
    // If model path is empty, then stop
    if(!strlen(sModel))
    {
        return 0;
    }
    
    // If model didn't exist, then
    if(!FileExists(sModel))
    {
        // Return error
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Models, "Config Validation", "Invalid model path. File not found: \"%s\"", sModel);
    }

    // If model doesn't precache yet, then continue
    if(!IsModelPrecached(sModel))
    {
        // Precache model sounds
        ModelsPrecacheSounds(sModel);
        
        // Precache model materails
        ModelsPrecacheMaterials(sModel);
        
        // Precache model resources
        ModelsPrecacheResources(sModel);
    }
    
    // Return the model index
    return PrecacheModel(sModel, true);
}


/**
 * Reads the current model and precache its resources.
 *
 * @param sModel            The model path.
 **/
stock void ModelsPrecacheResources(const char[] sModel)
{
    // Add file to download table
    AddFileToDownloadsTable(sModel);

    // Initialize some variables
    static char sResource[PLATFORM_MAX_PATH];
    static const char sTypes[3][] = { ".dx90.vtx", ".phy", ".vvd" };

    // Finds the first occurrence of a character in a string
    int iFormat = FindCharInString(sModel, '.', true);
    
    // i = resource type
    int iSize = sizeof(sTypes);
    for(int i = 0; i < iSize; i++)
    {
        // Extract value string
        StrExtract(sResource, sModel, 0, iFormat);
        
        // Format full path to file 
        Format(sResource, sizeof(sResource), "%s%s", sResource, sTypes[i]);
        
        // Validate resource
        if(FileExists(sResource)) 
        {
            // Add file to download table
            AddFileToDownloadsTable(sResource);
        }
    }
}

/**
 * Reads the current model and precache its sounds.
 *
 * @param sModel            The model path.
 * @return                  True if was precached, false otherwise.
 **/
stock bool ModelsPrecacheSounds(const char[] sModel)
{
    // Open the file
    File hFile = OpenFile(sModel, "rb");

    // If doesn't exist stop
    if(hFile == INVALID_HANDLE)
    {
        LogToGame("Error opening file: \"%s\"", sModel);
        return false;
    }
    
    // Initialize some variables
    static char sPath[PLATFORM_MAX_PATH]; int iChar; 

    do /// Reads a single binary char
    {
        hFile.Seek(2, SEEK_CUR);
        hFile.ReadInt8(iChar);
    } 
    while(iChar == 0);

    // Shift the cursor a bit
    hFile.Seek(1, SEEK_CUR);

    do /// Reads a single binary char
    {
        hFile.Seek(2, SEEK_CUR);
        hFile.ReadInt8(iChar);
    } 
    while(iChar != 0);

    // Loop throught the binary
    while(!hFile.EndOfFile())
    {
        // Reads a UTF8 or ANSI string from a file
        hFile.ReadString(sPath, sizeof(sPath));
        
        // Validate string
        //if(!IsByteString(sPath)) 
        //{
            // Finds the first occurrence of a character in a string
        int iFormat = FindCharInString(sPath, '.', true);

        // If file path is don't have format, then skip
        if(iFormat == -1) 
        {
            continue;
        }
        
        // Validate sound format
        if(!strcmp(sPath[iFormat], ".mp3", false) || !strcmp(sPath[iFormat], ".wav", false))
        {
            // Format full path to file
            Format(sPath, sizeof(sPath), "sound/%s", sPath);
            
            // Add file to download table
            PrecacheSoundAny(sPath);
            AddFileToDownloadsTable(sPath);
        }
        //}
    }

    // Close file
    delete hFile; 
    return true;
}

/**
 * Reads the current model and precache its materials.
 *
 * @param sModel            The model path.
 * @return                  True if was precached, false otherwise.
 **/
stock bool ModelsPrecacheMaterials(const char[] sModel)
{
    // Open the file
    File hFile = OpenFile(sModel, "rb");

    // If doesn't exist stop
    if(hFile == INVALID_HANDLE)
    {
        LogToGame("Error opening file: \"%s\"", sModel);
        return false;
    }
    
    // Initialize some variables
    static char sMaterial[PLATFORM_MAX_PATH]; static char sPath[PLATFORM_MAX_PATH]; int iNumMat; int iChar;

    // Find the total materials amount
    hFile.Seek(204, SEEK_SET);
    hFile.ReadInt32(iNumMat);
    hFile.Seek(0, SEEK_END);
    
    do /// Reads a single binary char
    {
        hFile.Seek(-2, SEEK_CUR);
        hFile.ReadInt8(iChar);
    } 
    while(iChar == 0);

    // Shift the cursor a bit
    hFile.Seek(1 , SEEK_CUR);

    do /// Reads a single binary char
    {
        hFile.Seek(-2, SEEK_CUR);
        hFile.ReadInt8(iChar);
    } 
    while(iChar != 0);

    // Reads a UTF8 or ANSI string from a file
    int iPosIndex = hFile.Position;
    hFile.ReadString(sMaterial, sizeof(sMaterial));
    hFile.Seek(iPosIndex, SEEK_SET);
    hFile.Seek(-1, SEEK_CUR);

    // i = material index
    for(int i = 0; i < iNumMat; i++)
    {
        do /// Reads a single binary char
        {
            hFile.Seek(-2, SEEK_CUR);
            hFile.ReadInt8(iChar);
        } 
        while(iChar != 0);

        // Reads a UTF8 or ANSI string from a file
        iPosIndex = hFile.Position;
        hFile.ReadString(sPath, sizeof(sPath));
        hFile.Seek(iPosIndex, SEEK_SET);
        
        // Validate size
        if(!strlen(sPath))
        {
            continue;
        }

        // Finds the first occurrence of a character in a string
        int iFormat = FindCharInString(sPath, '\\', true);

        // Validate no format
        if(iFormat != -1)
        {
            // Format full path to directory
            Format(sPath, sizeof(sPath), "materials\\%s", sPath);
    
            // Open the directory
            DirectoryListing hDirectory = OpenDirectory(sPath);
            
            // If doesn't exist stop
            if(hDirectory == INVALID_HANDLE)
            {
                continue;
            }
            
            // Initialize variables
            static char sFile[PLATFORM_MAX_PATH];
            
            // Initialize types
            FileType hType;
            
            // Search any files in the directory and precache them
            while(hDirectory.GetNext(sFile, sizeof(sFile), hType)) 
            {
                // Validate what found
                if(hType == FileType_File) 
                {
                    // Finds the first occurrence of a character in a string
                    iFormat = FindCharInString(sFile, '.', true);
            
                    // If file path is don't have format, then skip
                    if(iFormat == -1) 
                    {
                        continue;
                    }
                    
                    // Validate material format
                    if(!strcmp(sFile[iFormat], ".vmt", false))
                    {
                        // Format full path to file
                        Format(sFile, sizeof(sFile), "%s%s", sPath, sFile);
                        
                        // Precache model textures
                        ModelsPrecacheTextures(sFile);
                    }
                }
            }

            // Close directory
            delete hDirectory;
        }
        else
        {
            // Format full path to file
            Format(sPath, sizeof(sPath), "materials\\%s%s.vmt", sMaterial, sPath);
            
            // Precache model textures
            ModelsPrecacheTextures(sPath);
        }
    }
    
    // Close file
    delete hFile; 
    return true;
}

/**
 * Reads the current particle and precache its textures.
 *
 * @param sModel            The model path.
 * @return                  True if was precached, false otherwise.
 **/
stock bool ModelsPrecacheParticle(const char[] sModel)
{
    // Open the file
    File hFile = OpenFile(sModel, "rb");

    // If doesn't exist stop
    if(hFile == INVALID_HANDLE)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Models, "Config Validation", "Error opening file: \"%s\"", sModel);
        return false;
    }
    
    // Add file to download table
    AddFileToDownloadsTable(sModel);

    // Precache generic
    PrecacheGeneric(sModel, true); //! Precache only here

    // Initialize some variables
    static char sPath[PLATFORM_MAX_PATH]; int iChar;

    /// https://github.com/VSES/SourceEngine2007/blob/master/src_main/movieobjects/dmeparticlesystemdefinition.cpp
    /*static const char sParticleFuncTypes[48][SMALL_LINE_LENGTH] =
    {
        "DmeParticleSystemDefinition", "DmElement", "DmeParticleChild", "DmeParticleOperator", "particleSystemDefinitions",
        "preventNameBasedLookup", "particleSystemDefinitionDict", "snapshot", "untitled", "child", "drag", "delay", "name",
        "renderers", "operators", "initializers", "emitters", "children", "force", "constraints", "body", "duration", "DEBRIES",
        "color", "render", "radius", "lifetime", "type", "emit", "distance", "rotation", "speed", "fadeout", "DEBRIS", "size",
        "material", "function", "tint", "max", "min", "gravity", "scale", "rate", "time", "fade", "length", "definition", "thickness"
    };*/

    do /// Reads a single binary char
    {
        hFile.Seek(2, SEEK_CUR);
        hFile.ReadInt8(iChar);
    } 
    while(iChar == 0);

    // Shift the cursor a bit
    hFile.Seek(1, SEEK_CUR);

    do /// Reads a single binary char
    {
        hFile.Seek(2, SEEK_CUR);
        hFile.ReadInt8(iChar);
    } 
    while(iChar != 0);

    // Loop throught the binary
    while(!hFile.EndOfFile())
    {
        // Reads a UTF8 or ANSI string from a file
        hFile.ReadString(sPath, sizeof(sPath));

        // Validate string
        //if(!IsByteString(sPath)) 
        //{
            // Finds the first occurrence of a character in a string
            int iFormat = FindCharInString(sPath, '.', true);

            // Validate format
            if(iFormat != -1)
            {
                // Validate material format
                if(!strcmp(sPath[iFormat], ".vmt", false))
                {
                    // Format full path to file
                    Format(sPath, sizeof(sPath), "materials\\%s", sPath);
                    
                    // Precache model textures
                    ModelsPrecacheTextures(sPath);
                }
            }
            /*else
            {
                // Initialize variable
                bool bLookup;
                
                // i = type index
                for(int i = 0; i < sizeof(sParticleFuncTypes); i++)
                {
                    // Validate the common structure types
                    if(StrContains(sPath, sParticleFuncTypes[i], false) != -1)
                    {
                        bLookup = true; /// If was found, then stop
                        break;
                    }
                }
                
                // Validate search
                if(!bLookup)
                {
                    // Precache particle
                    fnPrecacheParticleEffect(sPath);
                }
            }*/
        //}
    }

    // Close file
    delete hFile;
    return true;
}

/**
 * Reads the current material and precache its textures.
 *
 * @param sPath             The texture path.
 * @param bDecal            (Optional) If true, the texture will be precached like a decal.
 * @return                  True if was precached, false otherwise.
 **/
stock bool ModelsPrecacheTextures(const char[] sPath)
{
    // Extract value string
    static char sTexture[PLATFORM_MAX_PATH];
    StrExtract(sTexture, sPath, 0, PLATFORM_MAX_PATH);

    // If doesn't exist stop
    if(!FileExists(sTexture))
    {
        LogToGame("Invalid material path. File not found: \"%s\"", sPath);
        return false;
    }

    // Add file to download table
    AddFileToDownloadsTable(sTexture);
    
    // Initialize some variables
    static const char sTypes[4][] = { "$baseTexture", "$bumpmap", "$lightwarptexture", "$REFRACTTINTtexture" }; bool bFound[sizeof(sTypes)]; static int iShift; int iSize = sizeof(sTypes);
    
    // Open the file
    File hFile = OpenFile(sTexture, "rt");
    
    // If doesn't exist stop
    if(hFile == INVALID_HANDLE)
    {
        LogToGame("Error opening file: \"%s\"", sTexture);
    }
    
    // Search textures lines in the file and precache it
    while(hFile.ReadLine(sTexture, sizeof(sTexture)))
    {
        // Cut out comments at the end of a line
        if(StrContains(sTexture, "//") != -1)
        {
            SplitString(sTexture, "//", sTexture, sizeof(sTexture));
        }
        
        // i = texture type
        for(int x = 0; x < iSize; x++)
        {
            // Avoid the reoccurrence 
            if(bFound[x]) 
            {
                continue;
            }
            
            // Validate type
            if((iShift = StrContains(sTexture, sTypes[x], false)) != -1)
            {
                // Shift the type away
                iShift += strlen(sTypes[x]) + 1;
        
                // Gets quotes at the beginning and at the end
                int iQuote1 = FindCharInString(sTexture[iShift], '"', true);
                int iQuote2 = FindCharInString(sTexture[iShift], '"', false);
                
                // Check if string without quote, then stop
                if(iQuote1 == -1 || iQuote2 == -1 || iQuote1 == iQuote2)
                {
                    LogToGame("Error with parsing \"%s\" in file: \"%s\"", sTypes[x], sPath);
                }
                else
                {
                    // Sets on the success
                    bFound[x] = true;
                    
                    // Extract value string
                    StrExtract(sTexture, sTexture[iShift], iQuote2 + 1, iQuote1);
                    
                    // Format full path to file
                    Format(sTexture, sizeof(sTexture), "materials\\%s.vtf", sTexture);
                    
                    // Validate size
                    if(!strlen(sTexture))
                    {
                        continue;
                    }
                    
                    // Validate material
                    if(FileExists(sTexture))
                    {
                        // Add file to download table
                        AddFileToDownloadsTable(sTexture);
                    }
                    else
                    {
                        LogToGame("Invalid texture path. File not found: \"%s\"", sTexture);
                    }
                }
            }
        }
    }

    // Close file
    delete hFile; 
    return true;
}

/**
 * Validates the specified standart models.
 *
 * @param sModel            The model path for validation.
 * @return                  The model index if was precached, 0 otherwise.
 **/
stock int ModelsPrecacheStandart(const char[] sModel)
{
    // Validate path
    if(!strncmp(sModel, "models/player/", 14, true))
    {
        // If path contains standart path
        if(!strncmp(sModel[14], "custom_player/legacy/", 21, true))
        {
            // If path contains standart path
            if(!strncmp(sModel[35], "ctm_", 4, true) || !strncmp(sModel[35], "tm_", 3, true))
            {
                // Precache model
                return PrecacheModel(sModel, true);
            }
        }
        else
        {
            // If path contains standart path
            if(!strncmp(sModel[14], "ctm_", 4, true) || !strncmp(sModel[14], "tm_", 3, true))
            {
                // Precache model
                return PrecacheModel(sModel, true);
            }
        }
    }
    else if(!strncmp(sModel, "models/weapons/", 15, true))
    {
        // If path contains standart path
        if(!strncmp(sModel[15], "ct_arms_", 8, true) || !strncmp(sModel[15], "t_arms_", 7, true))
        {
            // Precache model
            return PrecacheModel(sModel, true);
        }
    }

    // Model didn't exist, then stop
    LogToGame("Invalid model path. File not found: \"%s\"", sModel);
    return 0;
}  