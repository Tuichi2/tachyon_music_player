using Godot;
using System;
using System.IO;
using System.Linq;
//Este funciona para la version ejecutable
public partial class Arduino1 : Control
{
	[Export] private string musicFolder = "musica";
	[Export] private float tiempoParaDesactivarFoco = 5.0f;
	private Timer timerInactividad;
	private Control ultimoElementoConFoco = null;
	
	private AudioStreamPlayer reproductor;
	private OptionButton listaCanciones;
	private ProgressBar barraProgreso;
	private HSlider sliderPosicion;
	private HSlider sliderVolumen;
	private Label labelTiempo;
	private Label labelMusic; 
	
	private Button btnPlay, btnPause, btnStop, btnNext, btnPrev, btnLoop;
	private AnimatedSprite2D animsprite;
	
	private string[] canciones;
	private int indiceActual = 0;
	private bool arrastrandoSlider = false;
	private bool loopActivo = false;
	private bool primeraCarga = true; 

	private string animActual = "idle";
	private string animDanceActual = "";
	private float volumenActual => (float)sliderVolumen.Value;


	public override void _Ready()
	{	
		reproductor = GetNode<AudioStreamPlayer>("../Reproductor");
		listaCanciones = GetNode<OptionButton>("ListaCanciones/HBoxContainer2/ListaCancionesOpcion");
		barraProgreso = GetNode<ProgressBar>("ListaCanciones/BarraProgreso");
		sliderPosicion = GetNode<HSlider>("ListaCanciones/SliderPosicion");
		sliderVolumen = GetNode<HSlider>("ListaCanciones/HBoxContainer2/SliderVolumen");
		labelTiempo = GetNode<Label>("ListaCanciones/LabelTiempo");
		labelMusic = GetNode<Label>("../SubViewport/LabelMusic"); 

		btnPlay = GetNode<Button>("ListaCanciones/HBoxContainer/ButtonPlay");
		btnPause = GetNode<Button>("ListaCanciones/HBoxContainer/ButtonPause");
		btnStop = GetNode<Button>("ListaCanciones/HBoxContainer/ButtonStop");
		btnNext = GetNode<Button>("ListaCanciones/HBoxContainer/ButtonNext");
		btnPrev = GetNode<Button>("ListaCanciones/HBoxContainer/ButtonPrev");
		btnLoop = GetNode<Button>("ListaCanciones/HBoxContainer/ButtonLoop");
		
		animsprite = GetNode<AnimatedSprite2D>("../AnimatedSprite2D");
		animsprite.Play("idle");

		btnPlay.Pressed += OnPlayPressed;
		btnPause.Pressed += OnPausePressed;
		btnStop.Pressed += OnStopPressed;
		btnNext.Pressed += OnNextPressed;
		btnPrev.Pressed += OnPrevPressed;
		btnLoop.Pressed += OnLoopPressed;
		
		timerInactividad = new Timer();
		AddChild(timerInactividad);
		timerInactividad.WaitTime = tiempoParaDesactivarFoco;
		timerInactividad.Timeout += OnTiempoInactividad;
		timerInactividad.OneShot = true;
		
		this.GuiInput += OnGuiInput;
		ConectarSeñalesFoco();
		
		listaCanciones.ItemSelected += OnSongSelected;
		sliderPosicion.DragStarted += () => arrastrandoSlider = true;
		sliderPosicion.DragEnded += (bool changed) =>
		{
			arrastrandoSlider = false;
			if (changed)
				reproductor.Seek((float)sliderPosicion.Value);
		};
		
		sliderVolumen.ValueChanged += (double value) =>
		{
			AudioServer.SetBusVolumeDb(AudioServer.GetBusIndex("Master"), (float)Mathf.LinearToDb((float)value));
		};
		listaCanciones.CustomMinimumSize = new Vector2(450, 1);
		listaCanciones.SetAnchorsPreset(Control.LayoutPreset.CenterLeft);
		
		//Cargar canciones
		CargarCanciones();
		sliderVolumen.Value = 1.5f;
		
		ActualizarBotonLoop();
	}
	
	private void CargarCancion(int index, bool autoReproducir = true)
	{
		if (canciones.Length == 0)
			return;
			
		string nombreArchivo = canciones[index];
		string rutaAbsoluta = Path.Combine(OS.GetExecutablePath().GetBaseDir(), musicFolder, nombreArchivo);
		
		if (!File.Exists(rutaAbsoluta))
		{
			GD.PrintErr("No se encontró el archivo: " + rutaAbsoluta);
			return;
		}
		
		string extension = Path.GetExtension(nombreArchivo).ToLower();
		AudioStream stream = null;
		
		try
		{
			using var file = Godot.FileAccess.Open(rutaAbsoluta, Godot.FileAccess.ModeFlags.Read);
			var bytes = file.GetBuffer((long)file.GetLength());
			
			if (extension == ".mp3")
			{
				var temp = new AudioStreamMP3();
				temp.Data = bytes;
				stream = temp;
			}
			else if (extension == ".ogg")
			{
				stream = AudioStreamOggVorbis.LoadFromBuffer(bytes);
			}
			else if (extension == ".wav")
			{
				var temp = new AudioStreamWav();
				temp.Data = bytes;
				stream = temp;
			}
			else
			{
				GD.PrintErr("Formato no compatible: " + extension);
				return;
			}

			if (stream == null)
			{
				GD.PrintErr("No se pudo crear el stream para: " + nombreArchivo);
				return;
			}
			
			if (loopActivo)
			{
				if (stream is AudioStreamOggVorbis oggStream)
				{
					oggStream.Loop = true;
				}
				else if (stream is AudioStreamMP3 mp3Stream)
				{
					mp3Stream.Loop = true;
				}
				else if (stream is AudioStreamWav wavStream)
				{
					GD.Print("Error: Loop no disponible para WAV");
				}	
			}
			
			reproductor.Stream = stream;
		

			indiceActual = index;
			listaCanciones.Select(index);
			barraProgreso.Value = 0;
			sliderPosicion.Value = 0;
		
			string nombreSinExtension = Path.GetFileNameWithoutExtension(nombreArchivo);
			labelMusic.Text = nombreSinExtension;
		
			GD.Print("Reproduciendo: " + nombreSinExtension);
		
			string[] dances = {"dance1", "dance2", "dance3"};
			animDanceActual = dances[GD.Randi() % dances.Length];
		
			if (autoReproducir)
				OnPlayPressed();
		}
		catch (Exception e)
		{
			GD.PrintErr("Error al cargar canción: " + e.Message);
		}
	}
	
	private void CargarCanciones()
	{
		string carpetaMusicaReal = Path.Combine(OS.GetExecutablePath().GetBaseDir(), musicFolder);

		if (!Directory.Exists(carpetaMusicaReal))
		{
			Directory.CreateDirectory(carpetaMusicaReal);
			GD.Print("Carpeta de música creada: " + carpetaMusicaReal);
		}

		canciones = Directory.GetFiles(carpetaMusicaReal)
			.Where(f => f.EndsWith(".mp3") || f.EndsWith(".ogg") || f.EndsWith(".wav"))
			.Select(Path.GetFileName)
			.ToArray();

		listaCanciones.Clear();

		if (canciones.Length == 0)
		{
			listaCanciones.AddItem("Coloca tus canciones en la carpeta 'musica'");
			GD.Print("No se encontraron canciones en: " + carpetaMusicaReal);
			return;
		}

		for (int i = 0; i < canciones.Length; i++)
			listaCanciones.AddItem(Path.GetFileNameWithoutExtension(canciones[i]));

		CargarCancion(0, autoReproducir: false);

		GD.Print($"Se cargaron {canciones.Length} canciones desde {carpetaMusicaReal}");
	}

	
	private void OnPlayPressed()
	{
		reproductor.Play();
		
		if (volumenActual > 0.05f)
		{
			animsprite.Play(animDanceActual);
			animActual = animDanceActual;
		}
		else
		{
			animsprite.Play("idle");
			animActual = "idle";
		}
	}
	
	private void OnPausePressed()
	{
		reproductor.StreamPaused = !reproductor.StreamPaused;
		ActualizarAnimacion();
	}
	
	private void OnStopPressed()
	{
		reproductor.Stop();
		animsprite.Play("idle");
		animActual = "idle";
	}
	
	private void OnNextPressed()
	{
		if (canciones.Length == 0) return;
		indiceActual = (indiceActual + 1) % canciones.Length;
		CargarCancion(indiceActual);
	}
	
	private void OnPrevPressed()
	{
		if (canciones.Length == 0) return;
		indiceActual = (indiceActual - 1 + canciones.Length) % canciones.Length;
		CargarCancion(indiceActual);
	}
	private void OnLoopPressed()
	{
		loopActivo = !loopActivo;
		if (reproductor.Stream != null){
			if (reproductor.Stream is AudioStreamOggVorbis oggStream)
			{
				oggStream.Loop = loopActivo;
			}
			else if (reproductor.Stream is AudioStreamMP3 mp3Stream)
			{
				mp3Stream.Loop = loopActivo;
			}
			else if (reproductor.Stream is AudioStreamWav wavStream)
			{
				GD.Print("Error");
				//wavStream.Loop = loopActivo;
			}	
		}
		ActualizarBotonLoop();
		GD.Print("Loop " + (loopActivo ? "activado" : "desactivado"));
	}
	
	private void OnSongSelected(long index)
	{
		CargarCancion((int)index);
	}
	
	public override void _Process(double delta)
	{
		if (reproductor.Stream == null)
			return;
			
		float pos = reproductor.GetPlaybackPosition();
		float duracion = (float)reproductor.Stream.GetLength();
		
		if (!arrastrandoSlider)
		{
			barraProgreso.MaxValue = duracion;
			barraProgreso.Value = pos;
			sliderPosicion.MaxValue = duracion;
			sliderPosicion.Value = pos;
		}
		
		labelTiempo.Text = $"{FormatoTiempo(pos)} / {FormatoTiempo(duracion)}";
		
		if (!loopActivo && !reproductor.Playing && pos >= duracion - 0.1f)
		{
				OnNextPressed();
		}	
		ActualizarAnimacion();
	}
	
	private void ActualizarAnimacion()
	{
		if (reproductor.Playing && !reproductor.StreamPaused && volumenActual > 0.05f)
		{
			if (animActual != animDanceActual)
			{
				animsprite.Play(animDanceActual);
				animActual = animDanceActual;
			}
		}
		else
		{
			if (animActual != "idle")
			{
				animsprite.Play("idle");
				animActual = "idle";
			}
		}
	}
	
	private void ActualizarBotonLoop()
	{
		if (btnLoop != null)
		{
			btnLoop.Text = loopActivo ? "        Loop        " : "        Loop        ";
			btnLoop.Modulate = loopActivo ? new Color("c58281ff") : new Color(1, 1, 1);
		}
	}
	
	private string FormatoTiempo(float segundos)
	{
		int min = (int)(segundos / 60);
		int seg = (int)(segundos % 60);
		return $"{min:D2}:{seg:D2}";
	}
	private void ConectarSeñalesFoco()
	{
		// conectar a todos los controles que pueden recibir focus
		var controles = new Control[] 
		{
			listaCanciones, sliderPosicion, sliderVolumen,
			btnPlay, btnPause, btnStop, btnNext, btnPrev, btnLoop
		};
		
		foreach (var control in controles)
		{
			if (control != null)
			{
				control.FocusEntered += () => OnControlConFoco(control);
			}
		}
	}
	
	private void OnControlConFoco(Control control)
	{
		ultimoElementoConFoco = control;
		ReiniciarTimerInactividad();
	}

	private void OnGuiInput(InputEvent @event)
	{
		//reinicia ui
		if (@event is InputEventKey || @event is InputEventMouseButton)
		{
			ReiniciarTimerInactividad();
		}
	}
	
	private void ReiniciarTimerInactividad()
	{
		timerInactividad.Stop();
		timerInactividad.Start();
	}
	
	private void OnTiempoInactividad()
	{
		// Quitar el foco del elemento actual
		if (GetViewport().GuiGetFocusOwner() != null)
		{
			GetViewport().GuiReleaseFocus();
			ultimoElementoConFoco = null;
		}
	}
	
	// Método adicional para restaurar foco manualmente si lo necesitas
	public void RestaurarFoco()
	{
		if (ultimoElementoConFoco != null && ultimoElementoConFoco.Visible)
		{
			ultimoElementoConFoco.GrabFocus();
		}
		ReiniciarTimerInactividad();
	}
	
	public override void _UnhandledInput(InputEvent @event)
	{
		if (@event is not InputEventKey keyEvent || !keyEvent.Pressed)
			return;
		if (GetViewport().GuiGetFocusOwner() == null)
		{
			if (ultimoElementoConFoco != null && ultimoElementoConFoco.Visible)
			{
				ultimoElementoConFoco.GrabFocus();
			}
			else
			{
				btnPlay.GrabFocus();
			}
		}
	}
}
//hola chamo :v
