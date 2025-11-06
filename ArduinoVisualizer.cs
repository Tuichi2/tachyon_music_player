using Godot;
using System;
using System.IO.Ports;

public partial class ArduinoVisualizer : Node
{
	private SerialPort serialPort;

	[Export] float Sensibilidad = 10.0f;
	[Export] float Suavizado = 0.1f;
	private float nivelRojo = 0.0f;
	private float nivelAmarillo = 0.0f;
	private float nivelVerde = 0.0f;

	public override void _Ready()
	{
		serialPort = new SerialPort("COM9", 9600);
		try
		{
			serialPort.Open();
			GD.Print("Conectado al Arduino en COM9");
		}
		catch (Exception e)
		{
			GD.PrintErr("Error al conectar: ", e.Message);
		}
	}

	public override void _Process(double delta)
	{
		float volumenDb = AudioServer.GetBusPeakVolumeLeftDb(0, 0);
		float volumenLineal = Mathf.DbToLinear(volumenDb);
		float intensidad = Mathf.Clamp(volumenLineal * Sensibilidad, 0.0f, 1.0f);

		// Dividir la intensidad en rangos para cada led
		float targetRojo = Mathf.Clamp((intensidad - 0.6f) * 2.5f, 0.0f, 1.0f);
		float targetAmarillo = Mathf.Clamp((intensidad - 0.3f) * 3.0f, 0.0f, 1.0f);
		float targetVerde = Mathf.Clamp(intensidad * 3.0f, 0.0f, 1.0f);

		// suavizar transiciones
		nivelRojo = Mathf.Lerp(nivelRojo, targetRojo, Suavizado);
		nivelAmarillo = Mathf.Lerp(nivelAmarillo, targetAmarillo, Suavizado);
		nivelVerde = Mathf.Lerp(nivelVerde, targetVerde, Suavizado);

		// convierte a rango 0-255
		int rojo = (int)(nivelRojo * 255);
		int amarillo = (int)(nivelAmarillo * 255);
		int verde = (int)(nivelVerde * 255);

		// enviar en formato R,G,V
		EnviarComando($"{rojo},{amarillo},{verde}");
	}

	private void EnviarComando(string cmd)
	{
		if (serialPort != null && serialPort.IsOpen)
		{
			serialPort.WriteLine(cmd);
		}
	}

	public override void _ExitTree()
	{
		if (serialPort != null && serialPort.IsOpen)
			serialPort.Close();
	}
}
