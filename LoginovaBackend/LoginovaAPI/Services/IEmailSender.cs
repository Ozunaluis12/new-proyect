namespace LoginovaAPI.Services;

public interface IEmailSender
{
    Task EnviarAsync(string destinatario, string asunto, string cuerpoTexto);
}
