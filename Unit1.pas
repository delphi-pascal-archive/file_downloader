unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IdBaseComponent, IdComponent, IdTCPConnection,
  IdTCPClient, IdHTTP, OleCtrls, SHDocVw, XPMan, ComCtrls, Shellapi,
  IdIntercept, IdLogBase, IdLogStream, DateUtils, IdAntiFreezeBase,
  IdAntiFreeze, jpeg, ExtCtrls, Registry, Inifiles;

type
  TForm1 = class(TForm)
    IdHTTP1: TIdHTTP;
    XPManifest1: TXPManifest;
    ProgressBar: TProgressBar;
    IdAntiFreeze1: TIdAntiFreeze;
    ImageClose: TImage;
    ImageMin: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Bevel1: TBevel;
    Label3: TLabel;
    Memo: TMemo;
    Button1: TButton;
    procedure IdHTTP1WorkBegin(Sender: TObject; AWorkMode: TWorkMode;
      const AWorkCountMax: Integer);
    procedure IdHTTP1Work(Sender: TObject; AWorkMode: TWorkMode;
      const AWorkCount: Integer);
    procedure IdHTTP1WorkEnd(Sender: TObject; AWorkMode: TWorkMode);
    procedure ImageCloseClick(Sender: TObject);
    procedure ImageCloseMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure ImageMinMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure ImageMinClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  FStartDate : TDateTime;
  Num : Integer=0;
  Registre  : TRegistry;
  Directory, Comment : String;
  Version, NumVers : Integer;
const
  INTERNET_CONNECTION_MODEM           = 1;
  INTERNET_CONNECTION_LAN             = 2;
  INTERNET_CONNECTION_PROXY           = 4;
  INTERNET_CONNECTION_MODEM_BUSY      = 8;

function InternetGetConnectedState(lpdwFlags: LPDWORD;dwReserved: DWORD): BOOL; stdcall;  
implementation

function InternetGetConnectedState; external 'wininet.dll' name 'InternetGetConnectedState';

{$R *.dfm}


function Detection_Connexion :boolean;
var
  dwFlags : DWORD;
begin
  dwFlags :=INTERNET_CONNECTION_MODEM + INTERNET_CONNECTION_LAN
           + INTERNET_CONNECTION_PROXY ;
  RESULT := InternetGetConnectedState(@dwFlags,0);
end;

{/////////////////////////////////////////////////////////}
{//                     --- FORM ---                    //}
{/////////////////////////////////////////////////////////}
procedure TForm1.FormCreate(Sender: TObject);
begin
 if Detection_Connexion
 then Label1.Caption:='Internet connection is active ...'
 else
  begin
   Form1.Label1.Caption:='Pas de Connexion Internet active';
   MessageDlg('Votre connexion à Internet n''est pas activée. Veuillez vous connecter puis relancer le programme à nouveau.',mtError,[mbOk],0);
  end;
 IdAntiFreeze1.Active:=True;
end;

procedure TForm1.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  ImageClose.Picture.LoadFromFile('Close.jpg');
  ImageMin.Picture.LoadFromFile('min.jpg');
end;


{/////////////////////////////////////////////////////////}
{//                    --- IdHTTP ---                   //}
{/////////////////////////////////////////////////////////}

procedure TForm1.IdHTTP1Work(Sender: TObject; AWorkMode: TWorkMode;
  const AWorkCount: Integer);
var ElapsedTime : Cardinal;  
begin
   Label1.Caption:='Téléchargement en cours...';
   ImageClose.Enabled:=False;
   ImageClose.Picture.LoadFromFile('Close_3.jpg');

   if AWorkMode=wmRead then //quand on recoit des données
   begin
   ProgressBar.Position := AWorkCount + 40;
     ElapsedTime := SecondsBetween(Now,FStartDate); //Calcule la vitesse de téléchargement
     if ElapsedTime>0 then
     begin
       Label2.Caption := Format('Download speed: %s Kb/s',
            [FormatFloat('0.00',(AWorkCount/1024)/ElapsedTime)]);
       Application.ProcessMessages;   //Evite que l'appli soi "givrée"
     end;
   end;
 end;

procedure TForm1.IdHTTP1WorkBegin(Sender: TObject; AWorkMode: TWorkMode;
  const AWorkCountMax: Integer);
begin
   ProgressBar.Visible:=True;

   if AWorkMode = wmRead then //uniquement quand le composant recoit des données
   begin
      ProgressBar.Max := AWorkCountMax; //Maximum = taille du soft à télécharger
      ProgressBar.Position := 0; //Position à zéro
  end;
   if AWorkMode = wmRead then //uniquement quand le composant recoit des données
   begin
      Label2.Caption := 'Download speed: 0 Kb/s ';
      FStartDate := Now; //enregistre la date
      Application.ProcessMessages; //Evite que l'appli soit "gelée"
 end;
end;

procedure TForm1.IdHTTP1WorkEnd(Sender: TObject; AWorkMode: TWorkMode);
var  Ini : Tinifile;
begin
 if (Num=0) then      //Lecture de l'ini
  begin
    Ini := Tinifile.Create('Version.ini');
    NumVers := Ini.ReadInteger('Version','Numero',Num);
    Comment := Ini.ReadString('Comment','Text', '');
    Memo.Lines.Add(Comment);
    Label1.Caption:='Vérification des mises à jour...';
  end
 else
  Label1.Caption:='Téléchargement terminé avec succès.';
  Close;
  Application.ProcessMessages;
  Sleep(4000);  //Attend 4 sec avant de disparaitre
  Application.Terminate;
end;


{/////////////////////////////////////////////////////////}
{//                    --- IMAGES ---                   //}
{/////////////////////////////////////////////////////////}

procedure TForm1.ImageCloseMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  ImageClose.Picture.LoadFromFile('Close_2.jpg');
end;

procedure TForm1.ImageCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TForm1.ImageMinMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  ImageMin.Picture.LoadFromFile('min_2.jpg');
end;

procedure TForm1.ImageMinClick(Sender: TObject);
begin
  Application.Minimize;
end;


{/////////////////////////////////////////////////////////}
{//                     --- TIMER ---                   //}
{/////////////////////////////////////////////////////////}

procedure TForm1.Button1Click(Sender: TObject);
var Fil, FilIni:tmemorystream;
begin
  Registre := TRegistry.Create;

    With Registre Do
      Try

 RootKey := HKEY_LOCAL_MACHINE;
 OpenKey('Software\ClubinScr', True);

   If ValueExists('Version') Then
     Version := ReadInteger('Version');   //Lecture de la version dans la BdR

   If ValueExists('Directory') Then
     Directory := ReadString('Directory'); //Lecture du fichier dans la BdR

  FilIni:=TMemoryStream.Create;
 try
  Label1.Caption:='Vérification des mises à jour...';
  IdHttp1.Get('http://matt261.googlepages.com/Version.ini',FilIni);
  FilIni.SaveToFile('Version.ini');
except end;     

 if Detection_Connexion then else Exit;
  if (Version<NumVers) then else   //Si la version lue dans le fichier est plus grande ou = à celle lue dans la BdR
   begin
     MessageDlg('Vous possédez la dernière version de votre logiciel.'+#13+'Fermeture du programme de mises à jour.', mtInformation,[mbOK],0);
     Close;
     Exit;    //Exit pour éviter le plantage d'Indy
  end;


  Fil:=TMemoryStream.Create;
 try
  IdHttp1.Get('http://matt261.googlepages.com/Clubin.scr',Fil); //Vous pouvez changer le fichier à récuperer
  Fil.SaveToFile(ReadString('Directory'));     //Enregistrement dans le dossier indiqué dans la BdR
 except; end;
 finally
  Free;      //Libération de la BdR et de l'INI
  end;
end; 

end.
