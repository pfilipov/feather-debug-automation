$currentPath = 'C:\f\';
$projectCsproj = "D:\WorkRelated\Distributions\Sitefinity\9.2\Projects\SampleProject\SitefinityWebApp.csproj";
$logsFolder = "D:\WorkRelated\Temp";

$widgetsFolderName = "feather-widgets";
$commonBinFolderName = "common-bin";

$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe";

# get the folder
$newLocation = Get-ChildItem -Path $currentPath | where {$_.name -match ($widgetsFolderName)} |
select -First 1 | select -ExpandProperty FullName -ErrorAction SilentlyContinue;

# navigate to folder
Set-Location -Path $newLocation
# create the folder
New-Item $commonBinFolderName -ItemType directory

# get project files
$files = Get-ChildItem -Path $newLocation -Recurse -ErrorAction SilentlyContinue | where {$_.name -match ‘^Telerik.Sitefinity.Frontend.*\.csproj$’};

ForEach ($file In $files)
{
    $fileName = $file.FullName;
    # change the output folder to the common one
    $content = ([System.IO.File]::ReadAllText($fileName)).Replace("<OutputPath>bin\Debug\</OutputPath>","<OutputPath>..\common-bin</OutputPath>");
    [System.IO.File]::WriteAllText($fileName, $content);
}

# build only Feather projects, not the entire solution (There might be problems building the Tests)
ForEach ($file In $files)
{
    $fileName = $file.FullName;
    $name = $file.Name.Replace(".csproj","");
    $c = '/flp:logfile=' + $logsFolder + '\' + $name +'.log;errorsonly';
     ##     & $msbuild $fileName $c;
}

# fix references
$newReferenceFolder = $newLocation + "\" + $commonBinFolderName;
$xml = New-Object xml;
$xml.load($projectCsproj);
$references = $xml.Project.ItemGroup.Reference;
ForEach ($file In $files)
{
    $name = $file.Name.Replace(".csproj","");
    # fix for 9.1 where default project has 2 references to Events
    $referencesFiltered = $references | where { $_.Include -match $name };
    if($referencesFiltered -eq $null)
    {
       continue;
    }

    ForEach ($reference In $referencesFiltered)
    {
        # assumes project name and assembly name are the same
        $reference.HintPath = $newReferenceFolder + "\" + $name + ".dll";
    }
}
# save the project file
$xml.save([string]$projectCsproj);